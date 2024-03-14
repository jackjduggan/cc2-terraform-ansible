#!/bin/bash

# run Terraform output to get ip addresses
webserver1_ip=$(terraform output -raw webserver1_ip)
webserver2_ip=$(terraform output -raw webserver2_ip)
haproxy_ip=$(terraform output -raw haproxy_ip)
bastion_ip=$(terraform output -raw bastion_ip)

# create or overwrite Ansible hosts file
cat > hosts << EOF
# Ansible Inventory File

[webserver]
webserver1 ansible_host=${webserver1_ip}
webserver2 ansible_host=${webserver2_ip}

[haproxy]
haproxy1 ansible_host=${haproxy_ip}

[bastion]
bastion1 ansible_host=${bastion_ip}
EOF

echo "Ansible hosts file has been created/updated."
