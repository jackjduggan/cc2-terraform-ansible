#!/bin/bash

# run Terraform output to get ip addresses
webserver1_ip=$(terraform output -raw webserver1_ip)
webserver2_ip=$(terraform output -raw webserver2_ip)
haproxy_ip=$(terraform output -raw haproxy_ip)
#bastion_ip=$(terraform output -raw bastion_ip)

export ANSIBLE_HOST_KEY_CHECKING=False

# create or overwrite Ansible hosts file
cat > hosts << EOF
# Ansible Inventory File

[webserver]
webserver1 ansible_host=${webserver1_ip} ansible_user=jack ansible_ssh_private_key_file=~/.ssh/cc2-tf-ans-key-3.pem nginx_ip=${webserver1_ip}
webserver2 ansible_host=${webserver2_ip} ansible_user=jack ansible_ssh_private_key_file=~/.ssh/cc2-tf-ans-key-3.pem nginx_ip=${webserver2_ip}

[haproxy]
haproxy1 ansible_host=${haproxy_ip} ansible_user=jack ansible_ssh_private_key_file=~/.ssh/cc2-tf-ans-key-3.pem

#[bastion]
#bastion1 ansible_host=${bastion_ip} ansible_user=jack ansible_ssh_private_key_file=~/.ssh/cc2-tf-ans-key-3.pem
EOF

echo "Ansible hosts file has been created/updated."
