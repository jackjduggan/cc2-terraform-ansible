# Terraform, Ansible, AWS Provisioning/Configuration Assignment
### Jack Duggan

## Technologies Used
**Terraform**: Used for infrastructure as code to provision and manage cloud resources.\
**Ansible**: Utilized for configuration management to automate the software provisioning, configuration management, and application deployment.\
**Ansible Vault**: Employed to securely store and manage sensitive data through encrypted files.

## Terraform in the Project
Terraform is utilized in this project to automate the creation and management of cloud infrastructure. The specific tasks it performs include:

- Building a VPC: Sets up a Virtual Private Cloud to provide a logically isolated section of the cloud where you can launch resources.
- Configuring Subnets: Creates both private and public subnets; however, only public subnets are utilized in this project for simplicity and demonstration purposes.
- Security Group Configuration: Establishes a security group to define a set of firewall rules that control the traffic to and from instances.
- Provisioning Instances: Launches three instances:
  - One instance for the HAProxy load balancer.
  - Two instances serving as web servers.

## Ansible Playbooks
Ansible playbooks are integral to the project, managing the configuration of both the HAProxy load balancer and the webserver instances:

- HAProxy Configuration: The Ansible playbook for HAProxy installs and configures the HAProxy load balancer on its respective instance, setting up load balancing between the web servers.
- Webserver Setup: Another playbook is responsible for setting up the webservers, ensuring they are configured correctly and serving the expected content.

## Ansible Vault Usage 
The project leverages Ansible Vault to enhance security by encrypting sensitive data:
The secret_vars.yml file is encrypted using Ansible Vault, which contains sensitive variables that are crucial for the Ansible playbooks.
This approach ensures that sensitive information such as passwords, secret keys, or API tokens are securely managed and protected from unauthorized access.

## How to Run the Project
To run this project, follow these steps:

Cloning the project will require you to make your own `/roles/haproxy/vars/secret_vars.yml` file with contents similar to:
`haproxy_config_file: /etc/haproxy/haproxy.cfg`\
`ansible_connection: ssh`\
`ansible_ssh_common_args: '-o StrictHostKeyChecking=no'`\
You must then encrypt the file with Ansible Vault with the command:\
`$ ansible-vault encrypt roles/haproxy/vars/secret_vars.yml`\
... and create a 'secure' password file `.vault_pass.txt` with the password (not recommended for production)

You may then run the configuration manually with:
- `$ terraform init`
- `$ terraform apply`
- `$ ansible-playbook -i hosts roles/webserver/tasks/main.yml`
- `$ ansible-playbook -i hosts --vault-password-file .vault_pass.txt roles/haproxy/tasks/main.yml`
- `$ curl http://<haproxy_ip>`

Or you can run it automatically by simply running the script
- `$ sh main.sh`
However, you must ensure you have done the steps above for creating the `secret_vars.yml` and `.vault_pass.txt` file.
