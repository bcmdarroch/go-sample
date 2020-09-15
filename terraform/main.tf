# variables required for this file

# amazon machine image
variable "ami" {
    default = "ami-02354e95b39ca8dec" # variables without default will be required to be passed in at command line
}

variable "instance_type" {
    default = "t2.micro" # t family = burstable, can only use 100% sometimes, cheap!
}
 
variable "region" {
    default = "us-west-2"
}

# lets us run aws things
provider "aws" {
    version = "~> 3.0"
    region = "us-west-2"
}

# creates ecr repo
#         aws product          internal tf name   
resource "aws_ecr_repository" "go-sample" {
    name = "hello" # name of the image we want to push uo
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
    subnet_id = list(data.aws_subnet_ids.vpc1_public.ids)[0]
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