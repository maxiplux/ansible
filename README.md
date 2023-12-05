# ansible
## Terraform 
terraform init
terraform apply -auto-approve 

## 
pip install ansible
ansible -i hosts.ini all -m ping
ansible-playbook -i hosts.ini example-playbook.yml

##Final delelete all your AWS resources.
terraform  destroy -auto-approve 

