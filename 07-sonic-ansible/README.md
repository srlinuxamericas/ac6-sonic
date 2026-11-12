# Ansible with SONiC

## Use cases :
### 2- Network Inventory
Automating the network inventory to include:
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


### 1 - Multi-Tenants via VLAN 



 
