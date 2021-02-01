terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0" 
            region  = "us-west-2"
        }
    }
}

data "aws_ami" "RHEL" {
    most_recent     = true
    architecture    = "x86_64"

    filter {
        name    = "name"
        values  = [ "RHEL-8.3.0*" ]
    }   

    filter {
        name    = "virtualization-type"
        values  = [ "hvm" ]
    }
}

resource "aws_vpc" "awx-private" {
    cidr_block  = "10.0.0.0/28"
    tags = {
        Name = "awx-private"
        Cluster = "none"
        Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
        Environment = "dev"
        Creator = "terraform"
        Expires = "Never"
        Service = "private subnet"
        Management = "terraform"
    }
}

resource "aws_vpc" "awx-public" {
    cidr_block  = "10.1.0.0/28"
    tags = {
        Name = "awx-public"
        Cluster = "none"
        Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
        Environment = "dev"
        Creator = "terraform"
        Expires = "Never"
        Service = "public subnet"
        Management = "terraform"
    }
}

resource "aws_instance" "awx" {
    ami = data.aws_ami.RHEL.id
    instance_type = "t2.medium"
    tags = {
        Name = "awx"
        Cluster = "none"
        Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
        Environment = "dev"
        Creator = "terraform"
        Expires = "Never"
        Service = "awx"
        Management = "terraform"
    }

}