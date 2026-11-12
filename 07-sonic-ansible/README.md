# Ansible with SONiC
The objective of this section is to show practical automation use cases for a SONIC based Fabric.
It shows how to use the switches'management layer using gNMI and SSH where gNMI does not reach.
Using Ansible playbooks you will be able to collect and read the network state, make changes and verify the result without logging into each switch. 

## Use cases :
### 2- Network Inventory
Collect network inventory that include:
- switches in the fabric,
- ports,
- interfaces,
- IP addresses,
- BGP sessions
- VLAN to VNI mapping
  
Automation Files:  
- hosts                    --> inventory
- getinventory.yml        --> playbook
- ansible.cfg              --> configuration
- fabric-inventory.txt     --> report (output)

Running the playbook: 
```
sudo ansible-playbook -i hosts getinventory.yml
```
Verify the result
```
cat fabric-inventory.txt
```

### 1 - Multi-Tenants: Provisioning a tenant segment

A new tenant/customer needs a network segment, instead of logging to each leaf switch, you just need to provide the VLAN once and the playbook pushes it to all the switches via gNMI: 
1- Create VLAN (130) on leaf11 and leaf12
2- map the VLAN to the VNI on both leaves. 
3- Add the tenant's port to the VLAN

Automation Files:  
- hosts           --> inventory
- settenant.yml   --> playbook
- ansible.cfg     --> configuration

Prior to adding the tenant, let's verify the following on on **Leaf11**  and on **Leaf12** 

verify the VLAN members 
```
show vlan brief
```
Expected: VLANs 110, 200 and 999 — no VLAN 130.

<pre>
+-----------+----------------+------------+----------------+-------------+-----------------------+
|   VLAN ID | IP Address     | Ports      | Port Tagging   | Proxy ARP   | DHCP Helper Address   |
+===========+================+============+================+=============+=======================+
|       110 |                | Ethernet36 | untagged       | disabled    |                       |
+-----------+----------------+------------+----------------+-------------+-----------------------+
|       200 | 10.80.1.254/24 | Ethernet40 | untagged       | disabled    |                       |
+-----------+----------------+------------+----------------+-------------+-----------------------+
|       999 |                |            |                | disabled    |                       |
+-----------+----------------+------------+----------------+-------------+-----------------------+
</pre>

Verify VNI mapping

```
show vxlan vlanvnimap
```
Expected: No  Vlan130 mapping 
<pre>
+---------+-------+
| VLAN    |   VNI |
+=========+=======+
| Vlan110 | 10110 |
+---------+-------+
| Vlan200 | 10200 |
+---------+-------+
| Vlan999 | 10999 |
+---------+-------+
Total count : 3
</pre>  

Verify EVPN VNIs known to FRR

```
vtysh -c "show evpn vni"
```

expected: 
<pre>
VNI        Type VxLAN IF              # MACs   # ARPs   # Remote VTEPs  Tenant VRF                                                   
10110      L2   vtep-110              0        1        1               default                              
10200      L2   vtep-200              1        2        0               Vrf_Type5                            
10999      L3   vtep-999              1        1        n/a             Vrf_Type5 
</pre>


Note: you can run the inventory report before and after for full baseline:

```
ansible-playbook -i hosts getinventory.yml
```
**copy the report to a different name so it does not get overwritten** 
```
cp fabric-inventory.txt fabric-before.txt
```

Add the tenant to with vlan_id 130

```
ansible-playbook -i hosts set-tenant.yml -e vlan_id=130
```

Verify (run the previous verify commands) 
<pre>
   - show vlan brief — VLAN 130 appears, Ethernet40 tagged
   - show vxlan vlanvnimap — Vlan130 → 10130, total count 4
   - vtysh -c "show evpn vni" — a new 10130 L2 row on vtep-130, tenant VRF default
</pre>  

Test the ping client 4 from **client2** 
```
ping -c 3 172.16.30.4
```
Result:
<pre>
      client2:~# ping -c 3 172.16.30.4
      PING 172.16.30.4 (172.16.30.4) 56(84) bytes of data.
      64 bytes from 172.16.30.4: icmp_seq=1 ttl=64 time=2.61 ms
      64 bytes from 172.16.30.4: icmp_seq=2 ttl=64 time=2.04 ms
      64 bytes from 172.16.30.4: icmp_seq=3 ttl=64 time=2.00 ms
</pre>




 
