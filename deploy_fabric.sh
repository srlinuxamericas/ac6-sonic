
#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# SONiC EVPN Fabric - Lightweight Deployment
#
# Device    Management IP    Routing Mode
# ------------------------------------------------------------
# leaf11    172.40.40.2     unified
# leaf12    172.40.40.4     unified
# spine11   172.40.40.3     unified
# spine12   172.40.40.5     unified
#
# Installs:
#   - Patched SONiC YANG
#   - Patched FRR Jinja templates
#   - Node-specific CONFIG_DB
#   - Separate FRR configs for split-unified devices
# ============================================================

USER="admin"
PASS="admin"

NODES=(leaf11 leaf12 spine11 spine12)
IPS=(172.40.40.2 172.40.40.4 172.40.40.3 172.40.40.5)
MODES=(unified unified unified unified)

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$BASE/configs"
PATCH_DIR="$BASE/patches"

SSH_OPTS=(
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o LogLevel=ERROR
    -o ConnectTimeout=15
)

export SSHPASS="$PASS"

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================

command -v sshpass >/dev/null ||
    die "sshpass is not installed"

for f in \
    sonic-bgp-global.yang \
    frr.conf.j2 \
    bgpd.conf.db.j2
do
    [[ -s "$PATCH_DIR/$f" ]] ||
        die "Missing patch: $PATCH_DIR/$f"
done

for i in "${!NODES[@]}"; do

    NODE="${NODES[$i]}"
    MODE="${MODES[$i]}"

    [[ -s "$CONFIG_DIR/$NODE/config_db.json" ]] ||
        die "Missing CONFIG_DB for $NODE"

    if [[ "$MODE" == "split-unified" ]]; then
        [[ -s "$CONFIG_DIR/$NODE/$NODE.frr.conf" ]] ||
            die "Missing FRR config for $NODE"
    fi
done

# ============================================================
# CREATE REMOTE INSTALLER
# ============================================================

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/apply.sh" <<'REMOTE'
#!/usr/bin/env bash
set -Eeuo pipefail

NODE="$1"
MODE="$2"

STAGE="/tmp/sonic-deploy"
JINJA="/usr/local/sonic/frrcfgd"

echo "[$NODE] Installing SONiC YANG/Jinja patches..."

# ------------------------------------------------------------
# STEP 1 - INSTALL PATCHES
# ------------------------------------------------------------

install -m 644 \
    "$STAGE/sonic-bgp-global.yang" \
    /usr/local/yang-models/sonic-bgp-global.yang

install_jinja() {

    docker cp \
        "$STAGE/frr.conf.j2" \
        "bgp:$JINJA/frr.conf.j2"

    docker cp \
        "$STAGE/bgpd.conf.db.j2" \
        "bgp:$JINJA/bgpd.conf.db.j2"
}

# Small readiness check for newly booted VMs.
wait_bgp() {
    local i

    for i in $(seq 1 15); do
        if docker exec bgp true >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
    done

    return 1
}

wait_bgp || {
    echo "ERROR: BGP container unavailable."
    exit 1
}

install_jinja

# ------------------------------------------------------------
# STEP 2 - INSTALL CONFIG_DB
# ------------------------------------------------------------

echo "[$NODE] Installing CONFIG_DB..."

# Keep a copy of the previous startup configuration.
cp -a /etc/sonic/config_db.json \
    /etc/sonic/config_db.json.bak

install -m 644 \
    "$STAGE/config_db.json" \
    /etc/sonic/config_db.json

# ------------------------------------------------------------
# STEP 3 - RELOAD SONIC
# ------------------------------------------------------------

echo "[$NODE] Reloading SONiC configuration..."

config reload -y

# ------------------------------------------------------------
# STEP 4 - RESTORE JINJA PATCHES AFTER RELOAD
# ------------------------------------------------------------

echo "[$NODE] Ensuring Jinja patches are installed..."

wait_bgp || {
    echo "ERROR: BGP unavailable after reload."
    exit 1
}

# config reload may recreate the BGP container.
# Reinstall patched templates before the final BGP restart.
install_jinja

# ------------------------------------------------------------
# STEP 5 - ACTIVATE ROUTING CONFIGURATION
# ------------------------------------------------------------

if [[ "$MODE" == "unified" ]]; then

    echo "[$NODE] Activating unified FRR configuration..."

    # Regenerate FRR from CONFIG_DB using patched Jinja.
    docker restart bgp >/dev/null

else
    echo "[$NODE] Activating split-unified FRR configuration..."

    mkdir -p /etc/sonic/frr

    install -m 644 \
        "$STAGE/frr.conf" \
        /etc/sonic/frr/frr.conf

    chown root:root /etc/sonic/frr/frr.conf

    echo "[$NODE] Starting/restarting BGP..."

    if docker inspect -f '{{.State.Running}}' bgp | grep -qx true; then
        docker restart bgp >/dev/null
    else
        docker start bgp >/dev/null
    fi
fi


# ------------------------------------------------------------
# STEP 6 - BASIC COMPLETION CHECK
# ------------------------------------------------------------

wait_bgp || {
    echo "ERROR: BGP unavailable after restart."
    exit 1
}

echo "[$NODE] SUCCESS - $MODE configuration deployed."

REMOTE

# ============================================================
# DEPLOY ALL FOUR NODES
# ============================================================

for i in "${!NODES[@]}"; do

    NODE="${NODES[$i]}"
    IP="${IPS[$i]}"
    MODE="${MODES[$i]}"

    CFG="$CONFIG_DIR/$NODE"

    echo
    echo "========================================================"
    echo "Deploying $NODE ($IP) - $MODE"
    echo "========================================================"

    # --------------------------------------------------------
    # Prepare files for one bulk transfer.
    # --------------------------------------------------------

    FILES=(
        -C "$WORK" apply.sh
        -C "$PATCH_DIR"
            sonic-bgp-global.yang
            frr.conf.j2
            bgpd.conf.db.j2
        -C "$CFG" config_db.json
    )

    if [[ "$MODE" == "split-unified" ]]; then

        cp "$CFG/$NODE.frr.conf" "$WORK/frr.conf"

        FILES+=(
            -C "$WORK" frr.conf
        )
    fi

    # --------------------------------------------------------
    # Transfer all required files in one SSH session.
    # --------------------------------------------------------

    tar -cf - "${FILES[@]}" |
        sshpass -e ssh -T "${SSH_OPTS[@]}" \
            "$USER@$IP" \
            'mkdir -p /tmp/sonic-deploy &&
             tar -xf - -C /tmp/sonic-deploy' ||
        die "File transfer failed on $NODE"

    # --------------------------------------------------------
    # Execute the remote installer as root.
    # The installer runs sonic-cli as admin with its own TTY.
    # --------------------------------------------------------

    sshpass -e ssh -T "${SSH_OPTS[@]}" \
        "$USER@$IP" \
        "printf '%s\n' '$PASS' | sudo -S \
         bash /tmp/sonic-deploy/apply.sh '$NODE' '$MODE'" ||
        die "Deployment failed on $NODE"

    echo "[SUCCESS] $NODE ($MODE)"

done

echo
echo "========================================================"
echo " ALL FOUR SONIC DEVICES DEPLOYED SUCCESSFULLY"
echo "========================================================"

