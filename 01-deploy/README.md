# Building SONiC image and deploying the lab

## Lab Topology

Each workshop participant will be provided with the below topology consisting of 2 leaf and 2 spines nodes along with 2 clients. The Leaf-Spine architecture is typical in a Data Center environment and clients are simulating workloads or VMs.

![image](diagrams/lab-topology.png)

## NOS (Network Operating System)

All 4 switch nodes will be running the latest SONiC 202605 release.

SONiC NOS has 2 main Command Line Interfaces:

- SONiC (default cli) - sample prompt `admin@leaf1:~$`

  The SONiC configuration stores VLANs, interfaces, VRFs, and VXLAN mappings. Configuration is saved in `config_db.json`.
  
  To save SONiC configuration run:

  ```bash
  sudo config save -y
  ```
- FRR (enter using `vtysh` from SONiC bash CLI) - sample prompt `leaf1#`

  FRR stores BGP EVPN configuration and is saved in `/etc/frr/frr.conf`

  To save FRR configuration run:

  ```bash
  sudo vtysh -c "write memory"
  ```

For all configuration and show commands listed in this workshop, we specify the CLI from where it should be executed.

All 4 clients will be running [Alpine Linux](https://alpinelinux.org/)

## VM-based nodes in containerlab

VM nodes integration in containerlab is based on the [hellt/vrnetlab](https://github.com/hellt/vrnetlab) project which is a fork of `vrnetlab/vrnetlab` where things were added to make it work with the container networking.

Start with cloning the project:

```bash
cd ~ && git clone https://github.com/hellt/vrnetlab.git && \
cd ~/vrnetlab
```

### Building SONiC container image

SONiC vs image (downloaded from [sonic.software](https://sonic.software/)) is located at `~/images/sonic-vs-202605.qcow2` on your VM and should be copied to the `~/vrnetlab/sonic/` directory before building the container image.

```bash
cp ~/images/sonic-vs-202605.qcow2 ~/vrnetlab/sonic/
```

Once copied, we can enter in the `~/vrnetlab/sonic` image and build the container image:

```bash
cd ~/vrnetlab/sonic && make
```

The resulting image will be tagged as `vrnetlab/sonic_sonic-vs:202405`. This can be verified using 

```
docker images 
```

```bash
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
vrnetlab/sonic_sonic-vs   202605    33b73b1dadc4   5 minutes ago    6.37GB
```

## Deploying the SONiC lab

With the sonic image built, we can proceed with the lab deployment. We will deploy a lab with SONiC and SR Linux to show that Containerlab can have a VM based docker node and a native docker node in the same lab.

Use the below command to clone this repo to your VM.

```bash
sudo git clone https://github.com/srlinuxamericas/ac6-sonic.git
```

Verify that the git repo files are available on your VM.

```bash
ls -lrt ac6-sonic/
```

Now lets deploy the lab:

```bash
cd ac6-sonic
sudo clab dep -c
```

At the end of the deployment, the following table will be displayed. Wait for the sonic boot to be completed (see next section), before trying to login to sonic.

```bash
╭────────────────┬─────────────────────────────────────────────┬────────────────────┬────────────────╮
│      Name      │                  Kind/Image                 │        State       │ IPv4/6 Address │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ client11       │ linux                                       │ running            │ 172.40.40.10   │
│                │ ghcr.io/mfzhsn/network-multitool-sshd:0.0.5 │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ client12       │ linux                                       │ running            │ 172.40.40.11   │
│                │ ghcr.io/mfzhsn/network-multitool-sshd:0.0.5 │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ client13       │ linux                                       │ running            │ 172.40.40.12   │
│                │ ghcr.io/mfzhsn/network-multitool-sshd:0.0.5 │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ client14       │ linux                                       │ running            │ 172.40.40.13   │
│                │ ghcr.io/mfzhsn/network-multitool-sshd:0.0.5 │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ gnmic          │ linux                                       │ running            │ 172.40.40.6    │
│                │ ghcr.io/openconfig/gnmic:0.47.0             │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ gnmic-counters │ linux                                       │ running            │ 172.40.40.8    │
│                │ ghcr.io/openconfig/gnmic:0.47.0             │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ grafana        │ linux                                       │ running            │ 172.40.40.9    │
│                │ grafana/grafana:latest                      │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ leaf11         │ sonic-vm                                    │ running            │ 172.40.40.2    │
│                │ vrnetlab/sonic_sonic-vs:202605              │ (health: starting) │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ leaf12         │ sonic-vm                                    │ running            │ 172.40.40.4    │
│                │ vrnetlab/sonic_sonic-vs:202605              │ (health: starting) │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ prometheus     │ linux                                       │ running            │ 172.40.40.7    │
│                │ quay.io/prometheus/prometheus:v2.54.1       │                    │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ spine11        │ sonic-vm                                    │ running            │ 172.40.40.3    │
│                │ vrnetlab/sonic_sonic-vs:202605              │ (health: starting) │ N/A            │
├────────────────┼─────────────────────────────────────────────┼────────────────────┼────────────────┤
│ spine12        │ sonic-vm                                    │ running            │ 172.40.40.5    │
│                │ vrnetlab/sonic_sonic-vs:202605              │ (health: starting) │ N/A            │
╰────────────────┴─────────────────────────────────────────────┴────────────────────┴────────────────╯
```

### Monitoring the boot process

To monitor the boot process of SONiC, you can open a new terminal and run the following command:

```bash
sudo docker logs -f leaf11
```

> the SONiC boot time is approximately 1 minute.

Wait for the following message to appear in the boot logs which indicates the completion of the boot process and that the node is ready for login.

Verify that the below line is displayed on all 4 switches.

```bash
2026-11-04 16:25:23,960: launch         INFO Startup complete in: 0:01:46.508883
```

## Connecting to the nodes

To connect to SONiC node:

```bash
ssh admin@leaf11
```

Refer to the password in your card.

To login to any of the clients - `client1`, `client2`, `client3`, `client4`:

Username: `root`

Password: 'password'

Example:

```bash
ssh root@client1
```

Login to all 4 switches and verify the internal docker container for sonic functions are running:

```bash
docker ps
```

Expected output on each switch:

```bash
CONTAINER ID   IMAGE                                COMMAND                  CREATED              STATUS              PORTS     NAMES
8e11bc49d81e   docker-snmp:latest                   "/usr/bin/docker-snm…"   About a minute ago   Up About a minute             snmp
d7ba1f71b097   docker-platform-monitor:latest       "/usr/bin/docker_ini…"   About a minute ago   Up About a minute             pmon
5bb439d2bf1c   docker-sonic-mgmt-framework:latest   "/usr/local/bin/supe…"   About a minute ago   Up About a minute             mgmt-framework
4661015d8f25   docker-lldp:latest                   "/usr/bin/docker-lld…"   About a minute ago   Up About a minute             lldp
2321a0f89ada   docker-eventd:latest                 "/usr/local/bin/supe…"   3 minutes ago        Up 2 minutes                  eventd
e857528484b3   docker-gbsyncd-vs:latest             "/usr/local/bin/supe…"   3 minutes ago        Up 3 minutes                  gbsyncd
a6b4ed4259fe   docker-router-advertiser:latest      "/usr/bin/docker-ini…"   3 minutes ago        Up 3 minutes                  radv
de4cca2e012d   docker-sonic-gnmi:latest             "/usr/local/bin/supe…"   3 minutes ago        Up 3 minutes                  gnmi
5c25368c7d23   docker-fpm-frr:latest                "/usr/bin/docker_ini…"   3 minutes ago        Up 3 minutes                  bgp
7c944697c33c   docker-syncd-vs:latest               "/usr/local/bin/supe…"   3 minutes ago        Up 3 minutes                  syncd
99ff5e4e3d32   docker-teamd:latest                  "/usr/local/bin/supe…"   3 minutes ago        Up 3 minutes                  teamd
0e52fe9d3872   docker-sysmgr:latest                 "/usr/local/bin/supe…"   3 minutes ago        Up 3 minutes                  sysmgr
6173b320e176   docker-orchagent:latest              "/usr/bin/docker-ini…"   3 minutes ago        Up 3 minutes                  swss
3f033fe06c49   docker-database:latest               "/usr/local/bin/dock…"   3 minutes ago        Up 3 minutes                  database
```
