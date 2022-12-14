# Project_devops

############################
###### COMMAND RESUME ######
############################

**************************************
*******Ansible: useful command********
# Launch a playbook
- ansible-playbook -i hosts playbook.yml

**************************************
*******Vagrant: useful command********
# Create the vagrant file
- vagrant init

# Check if not error
- vagrant validate 

# To generate a virtual machine
- vagrant up

# Reload a Vagrantfile machine
- vagrant reload

# To get status virtual machine
- vagrant global-status 
- vagrant global-status --prune   (and clean the cache)

# To shutdown a virtual machine
- vagrant  halt ID/HOSTNAME
- vagrant  halt     (shutdown all)

# Launch a shell inside the machine
- vagrant ssh ID/HOSTNAME

# To delete a virtual machine
- vagrant destroy ID/HOSTNAME
- vagrant destroy       (shutdown all)

**************************************
*****Mesh&Consul: useful command******
# To access to the consul in browser
- http://IP_ADDRESS_MASTER:8500

# To access to the linkerd in browser
- http://IP_ADDRESS_NODE:9990

# Get metrics
- http://IP_ADDRESS_NODE/metrics

# Test server load balanced: 
- curl -H "Host:myapp" IP_ADDRESS:4040  OR  curl IP_ADDRESS:4040/myapp

# Set mode maintainance: 
- consul maint -enable

# Unset mode maintainance: 
- consul maint -disable

# Stop service my app: 
- service myapp stop

# Unset mode maintainance: 
- service myapp start

# Get status service linkerd:
- service linkerd status

# Get status service myapp:
- service myapp status

**************************************
*********Docker: useful command*******


**************************************
******Kubernetes: useful command******


**************************************
******Terraform: useful command*******

