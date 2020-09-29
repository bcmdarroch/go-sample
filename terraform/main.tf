# variables required for this file

# amazon machine image
variable "ami" {
    default = "ami-02354e95b39ca8dec" # variables without default will be required to be passed in at command line
}

variable "instance_type" {
    default = "t2.micro" # t family = burstable, can only use 100% sometimes, cheap!
}
 
variable "region" {
    default = "us-east-1"
}

# lets us run aws things
provider "aws" {
    version = "~> 3.0"
    region = var.region
}

# creates ecr repo
#         aws product          internal tf name   
resource "aws_ecr_repository" "go-sample" {
    name = "hello" # name of the image we want to push uo
}

locals {
  subnet_id = tolist(data.aws_subnet_ids.vpc1_public.ids)[0]
}

# create ec2 instance to run our nomad server on 
resource "aws_instance" "nomad" {
    ami = var.ami # get resolved by a variable
    instance_type = var.instance_type
    tags = {
        Name = "b-hewer-darroch-nomad-test"
        terminate = "anytime"
        owner = "b-hewer-darroch"
    }
    subnet_id = local.subnet_id
    vpc_security_group_ids = [aws_security_group.nomad_server.id]

    # runs as root only at the start of the instance 
    user_data = <<EOF
    #!/bin/bash
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCghBiCHBURbmY11Ny6/GmVDj7df8qYu+WCqSPH4oBfVoiyWOgig+gH/LngjBpP/rhi4BIbko5A02k+vqw8p1655DbF6KtHk2CUFmlVqatQU2FJMI9j7VOeDHqOa/BxKACj+UYZRfsbpQorRSeqRAjChzS3iNnSAVALhGwGiNBAkNj5MafIVronQ1mBFQZt1JpedCrjcWepkLKyUYWKJFMuElUhPNyUGuojKzfw2O8tL+ZMyAKI9/n61eA8vVdTaZx+sXuXOYXRGIDKBqDcvCOChZk4oXq3iSSs2gFlQTkTIVvRskwbogrDgPeYU4j1Tfo478SwHHO56bjrfDcQjlbBdCDjyADKqi47EzaZs9nvKcdhbYqZTpPNE4AsPekV7G6f9wbK1aTOBh6rzHpA2hdAgN20vKWDHqrNY0QzWMC3ypqem9fYREaaLtePXQFCktosxaecB9o3FOS/4quUFEhOrhDHi7kkesdSHG20vhXs9oaSVu4sh1Q9lb/uIZmMyr0RZd1jyCpjowwzhDLJseZ57+ipoY3Jq9i9blqnZjMuwodI3CuLd1rSww+QO4dQlF80OruFsbrxGo+ANG1OcIRVw575GQNGvZZ/jPEXTb1kr+Xc8jwEoxF4KhPMEHUiPbdfBRAS1KtZ9BKj9YwtnaaLcrAgwspGHqBxtN53P5alow== brenna@hashicorp.com" >> /home/ec2-user/.ssh/authorized_keys
    
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install nomad

    systemctl start nomad
    EOF
}

# data below from: https://github.com/hashicorp/terraform-aws-cloud-nomad-server/blob/master/datasources.tf
# already created by hashi
data "aws_vpc" "vpc1" {
  tags = {
    Name = "vpc1"
  }
}

data "aws_subnet_ids" "vpc1_public" {
  vpc_id = data.aws_vpc.vpc1.id
  filter {
    name = "tag:Name"
    values = [
      "vpc1-public-${var.region}a",
      "vpc1-public-${var.region}b",
      "vpc1-public-${var.region}c",
    ]
  }
}

resource "aws_security_group" "nomad_server" {
  name        = "test_nomad_server"
  description = "Sets rules for nomad server" # required, gets auto-set to "Managed by Terraform"
  vpc_id      = data.aws_vpc.vpc1.id

  ingress {
    description = "ssh from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.19.107.16/32"]
  }

  ingress {
    description = "nomad ui access"
    from_port   = 4646
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = ["73.19.107.16/32"]
  }

  # allows anything (0 = anything) 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # no bits are masked, every part of IP address can be anything
  }

  tags = {
    Name = "test_nomad_server"
    owner = "b-hewer-darroch"
    delete = "anytime"
  }
}

output "ip_address" {
  value = aws_instance.nomad.public_ip
}