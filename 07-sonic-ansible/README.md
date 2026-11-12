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
- getinventory.yaml        --> playbook
- ansible.cfg              --> configuration
- fabric-inventory.txt     --> report (output)

Running the playbook: 
```
ansible-playbook -i hosts getinventory.yml
```
Verify the result
```
cat fabric-inventory.txt
```

### 1 - Multi-Tenants via VLAN 



 
