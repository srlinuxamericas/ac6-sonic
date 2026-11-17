# Restoring Full Configuration

Use this section only if you run into a problem and need to re-deploy the lab with the full configuration.

# Steps to Re-deploy the lab

Change to the lab directory

```bash
cd ~/ac6-sonic
```

Destroy the lab with cleanup option

```bash
clab des -c
```

Deploy the lab again

```bash
clab dep -c
```

After nodes are UP and all SONiC docker containers are UP (check section [01-deploy](../01-deploy/)), change to the `full-config` directory

```bash
cd ~/ac6-sonic/full-config
```

Run the `deploy_fabric.sh` script

```bash
./deploy_fabric.sh
```

After the script execution is completed:

Login to **Leaf11** and change to FRR CLI:

```bash
vtysh
```

```bash
config
```

Open the `leaf11` FRR config file in a browser ([leaf11 FRR config](./configs/leaf11/leaf11.frr.conf)). Copy and paste this config on `leaf11`.

Login to **Leaf12** and change to FRR CLI:

```bash
vtysh
```

```bash
config
```

Open the `leaf12` FRR config file in a browser ([leaf12 FRR config](./configs/leaf12/leaf12.frr.conf)). Copy and paste this config on `leaf12`.

Verify BGP underlay and overlay neigbor status. Refer to commands in [02-sonic-bgp-evpn](../02-sonic-bgp-evpn/README.md) section. To verify EVPN status, run the ping tests between the clients as mentioned in this section.