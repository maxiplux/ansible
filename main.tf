terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-pem-ansible-dec04"
  public_key = tls_private_key.ssh.public_key_openssh


}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "terraform-pem-ansible-dec04.pem"
  file_permission = "0600"
}



# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    Name = "Terraform"
  }
}
resource "aws_internet_gateway" "terraform_vpc_internet_gateway" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "Terraform"
  }
}
resource "aws_route_table" "terraform_aws_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_vpc_internet_gateway.id
  }
}



resource "aws_subnet" "terraform_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Terraform"
  }
}
resource "aws_eip" "terraform_eip" {
  vpc = true
  tags = {
    Name = "Terraform"
  }
}
resource "aws_nat_gateway" "terraform_aws_nat_gateway" {
  allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.terraform_subnet.id
  tags = {
    Name = "Terraform"
  }
  depends_on = [ aws_internet_gateway.terraform_vpc_internet_gateway ]

}



resource "aws_route_table_association" "terraform_aws_route_table_association" {
  subnet_id      = aws_subnet.terraform_subnet.id
  route_table_id = aws_route_table.terraform_aws_route_table.id
}

resource "aws_network_interface" "terraform_network_interface" {
  subnet_id   = aws_subnet.terraform_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "Terraform",
  }
}

# ------------------------------------------------------
# Define un grupo de seguridad con acceso al puerto 8080
# ------------------------------------------------------
resource "aws_security_group" "terraform_security_group" {
  name   = "terraform_security_group-sg"
  vpc_id = aws_vpc.terraform_vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform",
  }
}



resource "aws_security_group" "terraform_security_icmp_group" {
  name   = "terraform_security_group-icmp-sg"
  vpc_id = aws_vpc.terraform_vpc.id
  ingress {
    //cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto ICMP desde el exterior"

    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Terraform",
  }
}

resource "aws_security_group" "terraform_security_ssh_group" {
  name   = "terraform_security_ssh_group-sg"
  vpc_id = aws_vpc.terraform_vpc.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 22 desde el exterior"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
  }

  tags = {
    Name = "Terraform",
  }
}
provider "tls" {}



resource "aws_instance" "terraform_instance_master" {
  ami           = "ami-053b0d53c279acc90"
  key_name = aws_key_pair.generated_key.key_name

  instance_type = "t2.micro"
  subnet_id = aws_subnet.terraform_subnet.id


  vpc_security_group_ids = [aws_security_group.terraform_security_icmp_group.id,aws_security_group.terraform_security_group.id, aws_security_group.terraform_security_ssh_group.id]
  tags = {
    Name = "Master",
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt-get install ec2-instance-connect -y
              sudo apt install apache2 -y
              sudo systemctl status sshd
              sudo systemctl start apache2

              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
}

resource "aws_instance" "terraform_instance_node1" {
  ami           = "ami-053b0d53c279acc90"
  key_name = aws_key_pair.generated_key.key_name

  instance_type = "t2.micro"
  subnet_id = aws_subnet.terraform_subnet.id


  vpc_security_group_ids = [aws_security_group.terraform_security_icmp_group.id,aws_security_group.terraform_security_group.id, aws_security_group.terraform_security_ssh_group.id]
  tags = {
    Name = "Node1",
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt-get install ec2-instance-connect -y
              sudo apt install apache2 -y
              sudo systemctl status sshd
              sudo systemctl start apache2

              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
}

resource "aws_instance" "terraform_instance_node2" {
  ami           = "ami-053b0d53c279acc90"
  key_name = aws_key_pair.generated_key.key_name

  instance_type = "t2.micro"
  subnet_id = aws_subnet.terraform_subnet.id


  vpc_security_group_ids = [aws_security_group.terraform_security_icmp_group.id,aws_security_group.terraform_security_group.id, aws_security_group.terraform_security_ssh_group.id]
  tags = {
    Name = "Node2",
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt-get install ec2-instance-connect -y
              sudo apt install apache2 -y
              sudo systemctl status sshd
              sudo systemctl start apache2

              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
}

output "server_private_ip" {
  value = [aws_instance.terraform_instance_master.private_ip,aws_instance.terraform_instance_node2.private_ip,aws_instance.terraform_instance_node1.private_ip]
}

output "server_public_dns" {
  value = [aws_instance.terraform_instance_master.public_dns]
}

output "server_public_ipv4" {
  value = [aws_instance.terraform_instance_master.public_ip]
}
output "server_id" {
  value = [aws_instance.terraform_instance_master.id]
}

//terraform output -raw private_key > terraform.pem
output "private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}