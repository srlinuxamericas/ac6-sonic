# Operationalizing SONiC in Modern Data Centers

Welcome to the workshop on *Operationalizing SONiC in Modern Data Centers* at Network Automation Forum's Autocon 6.

This README is your starting point into the hands on section.

Pre-requisite: A laptop with SSH client

If you need help, please raise your hand and a Nokia team member will be happy to assist.

Shortcut links to major sections in this README:

|   |
|---|
| [Build image and deploy lab](./01-deploy) |
| [Configure BGP and EVPN](./02-sonic-cli) |

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

### Using Codespaces

This lab can be deployed using GitHub Codespaces. Once you are logged into GitHub, click the below icon and wait for 2 minutes for codespaces to be ready.

Refer to instructions in the [Codespace](./Codespace) directory for importing the sonic image.

---
<div align=center>
<a href="https://codespaces.new/srlinuxamericas/ac6-sonic?quickstart=1">
<img src="https://gitlab.com/rdodin/pics/-/wikis/uploads/d78a6f9f6869b3ac3c286928dd52fa08/run_in_codespaces-v1.svg?sanitize=true" style="width:50%"/></a>

**[Run](https://codespaces.new/srlinuxamericas/ac6-sonic?quickstart=1) this lab in GitHub Codespaces for free**.  
[Learn more](https://containerlab.dev/manual/codespaces/) about Containerlab for Codespaces.

</div>

---

## Using gNMI with SONiC

### gNMI Get


### gNMI Set


### gNMI Subscribe


## SONiC Telemetry and Dashboards


## Packet capture


## SONiC Operations - Maitenance


## NETCONF Automation with SONiC


## Ansible Automation with SONiC

