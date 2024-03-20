#!/bin/bash

###
# Execution of this script kicks off an all-in-one lab setup.
# in the project root directory, execute 'sh main.sh'
###

# 1. Terraform Credentials Check
s3_output=$(aws s3 ls 2>&1)

if echo "$s3_output" | grep -q "An error occurred"; then
  echo "Error with AWS credentials: $s3_output"
  echo "Please check your credentials are configured and valid."
  exit 1
fi

echo "AWS credentials are valid... Proceeding"

# 2. Check for existing Terraform state
if [ -d ".terraform" ] || [ -f "terraform.tfstate" ]; then
    echo "Existing Terraform state found. Running 'terraform destroy' to clean up..."
    terraform destroy --auto-approve

    if [ $? -ne 0 ]; then
        echo "Terraform destroy failed. Please check the logs above for errors."
        exit 1
    fi
fi

# 3. Initialize and apply Terraform
terraform init

if [ $? -ne 0 ]; then
    echo "Terraform initialization failed. Please check the logs above for errors."
    exit 1
fi

terraform apply --auto-approve

if [ $? -ne 0 ]; then
    echo "Terraform apply failed. Please check the logs above for errors."
    exit 1
fi

echo "Terraform apply completed successfully."

# 4. Dynamic Inventory
# Check for the existence of the update_hosts.sh file and run it
if [ -f "update_hosts.sh" ]; then
    echo "Found update_hosts.sh. Executing the script..."
    ./update_hosts.sh

    if [ $? -ne 0 ]; then
        echo "Execution of update_hosts.sh failed. Please check the logs above for errors."
        exit 1
    fi
else
    echo "Error: update_hosts.sh does not exist. Please ensure the file is in the current directory."
    exit 1
fi

echo "Hosts script execution completed successfully."

# 5. Ansible

# Check for the existence of the Ansible playbook for the webserver
if [ -f "roles/webserver/tasks/main.yml" ]; then
    echo "Found webserver playbook. Executing Ansible playbook..."
    ansible-playbook -i hosts roles/webserver/tasks/main.yml

    if [ $? -ne 0 ]; then
        echo "Execution of the webserver playbook failed. Please check the logs above for errors."
        exit 1
    fi
else
    echo "Error: The webserver playbook roles/webserver/tasks/main.yml does not exist. Please ensure the file is present."
    exit 1
fi

# Check if the vault password file exists and has the correct permissions
vault_password_file=".vault_pass.txt"
if [ ! -f "$vault_password_file" ]; then
    echo "Error: Vault password file $vault_password_file does not exist."
    exit 1
fi

# Ensure the file permissions are set to 600
file_perm=$(stat -c "%a" "$vault_password_file")
if [ "$file_perm" -ne "600" ]; then
    echo "Error: Incorrect permissions on $vault_password_file. It should be 600."
    exit 1
fi

# Check for the existence of the Ansible playbook for HAProxy
if [ -f "roles/haproxy/tasks/main.yml" ]; then
    echo "Found HAProxy playbook. Executing Ansible playbook with Vault..."
    ansible-playbook -i hosts --vault-password-file "$vault_password_file" roles/haproxy/tasks/main.yml

    if [ $? -ne 0 ]; then
        echo "Execution of the HAProxy playbook failed. Please check the logs above for errors."
        exit 1
    fi
else
    echo "Error: The HAProxy playbook roles/haproxy/tasks/main.yml does not exist. Please ensure the file is present."
    exit 1
fi

echo "Ansible playbook for HAProxy executed successfully."

# 6. Verify HAProxy is load balancing
# Fetch the IP address of the HAProxy instance using Terraform
haproxy_ip=$(terraform output -raw haproxy_ip)

# Verify if the IP address was successfully retrieved
if [ -z "$haproxy_ip" ]; then
    echo "Failed to retrieve HAProxy IP address from Terraform."
    exit 1
fi

echo "HAProxy IP address: $haproxy_ip"

# Curl the HAProxy instance and check for the expected phrase
curl_output=$(curl -s http://$haproxy_ip)

if echo "$curl_output" | grep -q ":)"; then
    echo "Success: The curl command retrieved the expected output."
else
    echo "Error: The output from the HAProxy instance did not contain the expected phrase ':)'."
    exit 1
fi

echo "Verification completed successfully."
