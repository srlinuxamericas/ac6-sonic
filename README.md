# Operationalizing SONiC in Modern Data Centers

Welcome to the workshop on *Operationalizing SONiC in Modern Data Centers* at Network Automation Forum's Autocon 6.

This README is your starting point into the hands on section.

Pre-requisite: A laptop with SSH client

If you need help, please raise your hand and a Nokia team member will be happy to assist.

Shortcut links to major sections in this README:

|   |   |
|---|---|
| [Lab Topology](#lab-topology) | [Building SONiC image](#Building-SONiC-container-image) |
| [Lab Topology](#lab-topology) | [Deploying the lab](#0-deploying-the-sonic-lab) |

## Lab Environment

A Nokia team member will provide you with a card that contains:
- your VM hostname
- SSH credentials to the VM instance
- URL of this repo

> <p style="color:red">!!! Make sure to backup any code, config, ... <u> offline (e.g on your laptop)</u>. 
> The VM instances will be destroyed once the Workshop is concluded.</p>

## Workshop
The objective of the hands on section of this workshop is the following:
- Build a SONiC image for Containerlab
- Deploy a SONiC leaf-spine fabric with Containerlab
- Configure EVPN on SONiC
- Use gNMI for configuration and streaming Telemetry
- SONiC observability using dashboards
- Automate configuration tasks
- Simulate a Maintenance operation

## Lab Topology

Each workshop participant will be provided with the below topology consisting of 2 leaf and 2 spines nodes along with 2 clients. The Leaf-Spine architecture is typical in a Data Center environment and clients are simulating workloads or VMs.

```mermaid
graph TD
    %% Nodes
    spine11["spine11<br/>AS 65000"]
    spine12["spine12<br/>AS 65000"]
    leaf11["leaf11<br/>AS 65001"]
    leaf12["leaf12<br/>AS 65002"]
    
    client11["client11 (L2VPN)<br/>172.16.10.50/24"]
    client12["client12 (L3VPN)<br/>10.80.1.1/24"]
    client13["client13 (L2VPN)<br/>172.16.10.60/24"]
    client14["client14 (L3VPN)<br/>10.90.1.1/24"]

    %% Backbone Links
    spine11 ---|eth1 <----> eth1| leaf11
    spine11 ---|eth2 <----> eth1| leaf12
    spine12 ---|eth1 <----> eth2| leaf11
    spine12 ---|eth2 <----> eth2| leaf12

    %% Access Links
    leaf11 ---|eth10 <----> eth1| client11
    leaf11 ---|eth11 <----> eth1| client12
    leaf12 ---|eth10 <----> eth1| client13
    leaf12 ---|eth11 <----> eth1| client14

    %% Styling
    classDef spine fill:#2d3748,stroke:#4a5568,stroke-width:2px,color:#fff;
    classDef leaf fill:#1a365d,stroke:#2b6cb0,stroke-width:2px,color:#fff;
    classDef client fill:#22543d,stroke:#2f855a,stroke-width:1px,color:#fff;
    
    class spine11,spine12 spine;
    class leaf11,leaf12 leaf;
    class client11,client12,client13,client14 client;
```

![image](images/lab-topology.jpg)

## NOS (Network Operating System)

Both leafs and Spine nodes will be running the 202605 release of SONiC.

Both clients will be running a light version of [Alpine Linux](https://alpinelinux.org/).

See the [topology](ac6-sonic.clab.yml) file for more details.

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

The resulting image will be tagged as `vrnetlab/sonic_sonic-vs:202405`. This can be verified using `docker images` command.

```bash
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
vrnetlab/sonic_sonic-vs   202605    33b73b1dadc4   5 minutes ago    6.37GB
```

## Deploying the SONiC lab

With the sonic image built, we can proceed with the lab deployment. We will deploy a lab with SONiC and SR Linux to show that Containerlab can have a VM based docker node and a native docker node in the same lab.

First, let's switch back to the lab directory:

```bash
cd ~/ac6-sonic
```

Now lets deploy the lab:

```bash
sudo clab dep -c
```

At the end of the deployment, the following table will be displayed. Wait for the sonic boot to be completed (see next section), before trying to login to sonic.

```bash
TODO
```

### Monitoring the boot process

To monitor the boot process of SONiC, you can open a new terminal and run the following command:

```bash
sudo docker logs -f leaf1
```

> the SONiC boot time is approximately 1 minute.

## Connecting to the nodes

To connect to SONiC node:

```bash
ssh admin@leaf1
```

Refer to the password in your card.
