# Maintenance Operations with SONiC

In this section we will prepare a spine switch for maintenance by draining traffic from the spine.

We will use standard BGP GRACEFUL_SHUTDOWN community (65535:0) for this purpose.

Before the start of the maintenance window, the spine undergoing maintenance will advertise this community to all its peers.

Upon receiving this community, the leaf switches will update BGP `local-preference` value to 0 for routes advertised by the spine.

Traffic will then move over to the other spine allowing for maintenance operations.

## Configure Route Policies on Leaf switches

Our first step is to configure the route policy on the leafs to set `local-preference` when GSHUT community is received.

This configuration will be pushed via FRR CLI.

On **leaf11** and **leaf12** (copy and paste to both switches after typing `vtysh`):

```bash
configure
bgp community-list standard CL_GSHUT seq 5 permit graceful-shutdown
route-map RM_EVPN_GSHUT_IN permit 10
match community CL_GSHUT
set local-preference 0
exit
!
route-map RM_EVPN_GSHUT_IN permit 20
exit
!
```

Apply this policy to both BGP underlay and overlay neighbors.

On **leaf11** using **FRR CLI**:

```bash
router bgp 64501
address-family ipv4 unicast
neighbor 192.168.10.3 route-map RM_EVPN_GSHUT_IN in
neighbor 192.168.12.3 route-map RM_EVPN_GSHUT_IN in

address-family l2vpn evpn
neighbor 11.11.11.11 route-map RM_EVPN_GSHUT_IN in
neighbor 22.22.22.22 route-map RM_EVPN_GSHUT_IN in
```

On **leaf12** using **FRR CLI**:

```bash
router bgp 64502
address-family ipv4 unicast
neighbor 192.168.20.3 route-map RM_EVPN_GSHUT_IN in
neighbor 192.168.22.3 route-map RM_EVPN_GSHUT_IN in

address-family l2vpn evpn
neighbor 11.11.11.11 route-map RM_EVPN_GSHUT_IN in
neighbor 22.22.22.22 route-map RM_EVPN_GSHUT_IN in
```

## Configure Route Policies on Spine switches

Next we will configure route policies on the Spine switches to send out GSHUT community.

The policy will only be applied at the time of the maintenance window.

We will use gNMI to push these policies to the Spine switches.

From your VM, run the below commands to push policy to **Spine11**:

```bash
gnmic -a spine11:8080 -u admin -p admin --insecure \
  -e json_ietf set \
  --update-path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP_SET' \
  --update-value '{"RM_SPINE_GSHUT_OUT": {}}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/RM_SPINE_GSHUT_OUT|10' \
  --update-value '{"route_operation": "permit","set_community_inline": ["graceful-shutdown","additive"]}'
```

From your VM, run the below commands to push policy to **Spine12**:

```bash
gnmic -a spine12:8080 -u admin -p admin --insecure \
  -e json_ietf set \
  --update-path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP_SET' \
  --update-value '{"RM_SPINE_GSHUT_OUT": {}}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/RM_SPINE_GSHUT_OUT|10' \
  --update-value '{"route_operation": "permit","set_community_inline": ["graceful-shutdown","additive"]}'
```

## Send traffic

Before simulating the maitenance window, start traffic between the clients.

Login to **client1** and run:

```bash
iperf3 -s
```

Login to **client3** and run:

```bash
iperf3 -c 172.16.10.50 -u -P 5 -l 1200 -b 4M -t 900
```

## Check Grafana Dashboards to find active spine

Open the Grafana dashboard for your VM and check which spine is taking in all the traffic.

We will simulate a traffic drain on that active spine switch.

Based on which spine is currently taking traffic, run only one of the below 2 sections. Do not run both sections which will cause an outage scenario.

## If Spine11 is active

On the Grafana dashboard, if **Spine11** is active spine taking all the traffic, run the below commands to drain the traffic from `spine11` in order to simulate a maitenance window.

These commands apply the previously created GSHUT route policies to both underlay and overlay neighbors of the spine.

Run these `gnmic` commands from the VM:

```bash
gnmic -a spine11:8080 --insecure \
  -e json_ietf set \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.10.2|ipv4_unicast' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.20.2|ipv4_unicast' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|1.1.1.1|l2vpn_evpn' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|2.2.2.2|l2vpn_evpn' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}'
```

## If Spine12 is active

On the Grafana dashboard, if **Spine12** is active spine taking all the traffic, run the below commands to drain the traffic from `spine12` in order to simulate a maitenance window.

These commands apply the previously created GSHUT route policies to both underlay and overlay neighbors of the spine.

Run these `gnmic` commands from the VM:

```bash
gnmic -a spine12:8080 --insecure \
  -e json_ietf set \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.12.2|ipv4_unicast' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.22.2|ipv4_unicast' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|1.1.1.1|l2vpn_evpn' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|2.2.2.2|l2vpn_evpn' \
  --update-value '{"admin_status":"up","route_map_out":["RM_SPINE_GSHUT_OUT"]}'
```

## Monitor Grafana

Check the Grafana dashboard to verify traffic drain from the active spine and traffic switchover to the other spine.

## Post Maintenance

After maintenance is completed, the policies can be removed from the BGP neighbors of the spine so that traffic will be back on the spine.

If **Spine11** was taken out for maintanance, run the below commands from the VM to remove the route policy from the BGP neighbors:

```bash
gnmic -a spine11:8080 --insecure   -e json_ietf set   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.10.2|ipv4_unicast/route_map_out'   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.20.2|ipv4_unicast/route_map_out'
```

```bash
gnmic -a spine11:8080 --insecure   -e json_ietf set   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|1.1.1.1|l2vpn_evpn/route_map_out'   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|2.2.2.2|l2vpn_evpn/route_map_out'
```

If **Spine12** was taken out for maintanance, run the below commands from the VM to remove the route policy from the BGP neighbors:

```bash
gnmic -a spine12:8080 --insecure   -e json_ietf set   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.12.2|ipv4_unicast/route_map_out'   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|192.168.22.2|ipv4_unicast/route_map_out'
```

```bash
gnmic -a spine12:8080 --insecure   -e json_ietf set   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|1.1.1.1|l2vpn_evpn/route_map_out'   --delete 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR_AF/default|2.2.2.2|l2vpn_evpn/route_map_out'
```

This completes the maintenance window section.

## Next Section:   [SONiC PCAP](https://github.com/srlinuxamericas/ac6-sonic/tree/main/07-sonic-pcap)
