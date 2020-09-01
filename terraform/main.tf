# variables required for this file

# amazon machine image
variable "ami" {
    default = "ami-02354e95b39ca8dec" # variables without default will be required to be passed in at command line
}

variable "instance_type" {
    default = "t2.micro" # t family = burstable, can only use 100% sometimes, cheap!
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
    # TODO assign to a network
}