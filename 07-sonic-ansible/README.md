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

### 1 - Multi-Tenants via VLAN 

New tenant/customer needs a network segment, instead of logging to each leaf switch, you just need to provide the VLAN once and the playbook will push it to all the switches via gNMI: 
1- Creare VLAN on leaf11 and leaf12
2- map the VLAN to the VNI on both leaves. 
3- Put the tenna't port into the VLAN

Automation Files:  
- hosts           --> inventory
- settenant.yml   --> playbook
- ansible.cfg     --> configuration

Prior to adding the tenant, let's verify the following on on **Leaf11**  and on **Leaf12** 

verify the VLAN members 
```
show vlan brief
```
Expected: only VLAN ID 110 with Ethernet36 as a member

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
Expected: only Vlan110 mapped to VNI 10110 

+---------+-------+
| VLAN    |   VNI |
+=========+=======+
| Vlan110 | 10110 |
+---------+-------+

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
``

Compare the results ..





 
