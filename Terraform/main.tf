#-----------------------------------------------------
# iSlade1 project
#-----------------------------------------------------

# Credentials for AWS provider

provider "aws" {
  profile = "iSlade1"
  region  = "eu-central-1"
}

# AWS Data Source AMI

data "aws_ami" "Latest_Ubuntu" {
  owners      = ["099720109477"] # AMI Owner
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] # Latest Ubuntu 20.04 LTS AMI
  }
}

# Just output information about latest AMI from AWS Data Source

output "Latest_ubuntu_ami_id" {
  value = data.aws_ami.Latest_Ubuntu.id # Output Latest_Ubuntu id
}

output "Latest_ubuntu_ami_name" {
  value = data.aws_ami.Latest_Ubuntu.name # Output Latest_Ubuntu name
}

# Creating AWS instance on Ubuntu for Jenkins

resource "aws_instance" "Jenkins" {
  ami                    = data.aws_ami.Latest_Ubuntu.id # Ubuntu 20.04 LTS AMI
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ports.id] # Attach Security Group
  user_data              = <<EOF
#!/bin/bash
sudo apt update
sudo apt install openjdk-8-jdk
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins
sudo systemctl start jenkins
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw allow 8080
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
EOF
}

# Creating AWS instances on Ubuntu for Apache WebServer

resource "aws_instance" "Test_Env" {
  ami                    = data.aws_ami.Latest_Ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  user_data              = <<EOF
#!/bin/bash
sudo apt update
sudo apt install apache2
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw allow 'Apache'
sudo systemctl status apache2
EOF
}

resource "aws_instance" "Prod_Env" {
  ami                    = data.aws_ami.Latest_Ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  ser_data               = <<EOF
#!/bin/bash
sudo apt update
sudo apt install apache2
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw allow 'Apache'
sudo systemctl status apache2
EOF
}

# Security group

resource "aws_security_group" "allow_ports" {
  name        = "WebServer Security Group"
  description = "Allow TCP inbound traffic"

  ingress {
    description = "HTTPS allow"
    from_port   = 443 # Allow HTTPS conection
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP allow"
    from_port   = 80 # Allow HTTP conection
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP allow"
    from_port   = 22 # Allow TCP conection
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS allow"
    from_port   = 8080 # Allow Jenkins conection
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
