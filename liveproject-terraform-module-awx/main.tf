terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0" 
        }
    }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "RHEL" {
    most_recent     = true
    owners          = ["309956199498"] # RedHat

    filter {
        name    = "name"
        values  = [ "RHEL-8.3.0_HVM*-x86_64*" ]
    }   

    filter {
        name    = "virtualization-type"
        values  = [ "hvm" ]
    }
}

resource "aws_vpc" "awx" {
    cidr_block  = "10.1.0.0/16"
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

resource "aws_subnet" "awx-public-subnet" {
  vpc_id            = aws_vpc.awx.id
  cidr_block        = "10.1.2.0/24"

  tags = {
    Name = "awx public subnet"
    Cluster = "none"
    Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
    Environment = "dev"
    Creator = "terraform"
    Expires = "Never"
    Service = "awx"
    Management = "terraform"
  }
}

resource "aws_subnet" "awx-private-subnet" {
  vpc_id            = aws_vpc.awx.id
  cidr_block        = "10.1.3.0/24"

  tags = {
    Name = "awx private subnet"
    Cluster = "none"
    Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
    Environment = "dev"
    Creator = "terraform"
    Expires = "Never"
    Service = "awx"
    Management = "terraform"
  }
}

resource "aws_nat_gateway" "awx-nat-gw" {
  allocation_id = aws_vpc.awx.id
  subnet_id     = aws_subnet.awx-private-subnet.id

  tags = {
    Name = "AWX NAT GW"
    Cluster = "none"
    Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
    Environment = "dev"
    Creator = "terraform"
    Expires = "Never"
    Service = "nat-gw"
    Management = "terraform"
  }
}

resource "aws_internet_gateway" "awx-internet-gw" {
  vpc_id = aws_vpc.awx.id

  tags = {
    Name = "awx-internet-gw"
    Cluster = "none"
    Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
    Environment = "dev"
    Creator = "terraform"
    Expires = "Never"
    Service = "internet-gw"
    Management = "terraform"
  }
}

resource "aws_network_interface" "awx-interface" {
  subnet_id   = aws_subnet.awx-public-subnet.id
  private_ips = ["10.1.2.10"]

  tags = {
    Name = "awx primary interface"
    Cluster = "none"
    Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
    Environment = "dev"
    Creator = "terraform"
    Expires = "Never"
    Service = "awx"
    Management = "terraform"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "liveproject-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7BY/XLvHkUfRWnwGKFJGQPYIOFNMVH/v132mJBTmyi2kDFWdFKZujZ5xiE0pG9IAP6GtTqaHfenCQNTuYPcR3x1XJkXJXbUOw4srxIE8rId3/orK3uGN2e9imd4DVCSxNq/tXrzG3gUAwxVqNG4WHcDz0PsOztm6uB/zbzu8d1Mp8uF1rrBHN3rz0YWQHNkoaH3WZSYkXnSxp04C5foY++L2qWODXKOaqfxn3dZk3+Qc7n0ANb5o5vHAzskODptorzOpfp2U9LZxeAhOhRkP8IAWt5wvSwHfIWADv9G1x/iHUMp1HvEKInr2Mv9H1sVLnggoxKBIj6UcjxIxacEJxFpfh7uwb0MnUOSANGkgPMuqwSBtRfb8Hi1QLOplgsRDMowTcv8IDSzMBVxmy0oBMNUvxss6Tvg4uYoxeBtThnpF544QWPZYrUvjn1NdHUmJEYp28+9TK7Y1iaG4u5BMT8BIU3IcwSweLBKXxlii6tmJf3jnyUhUeTqzgYf4BgO0= ec2-user@ip-172-31-42-246.us-east-2.compute.internal"

  tags = {
        Name = "awx ssh keypair"
        Cluster = "none"
        Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
        Environment = "dev"
        Creator = "terraform"
        Expires = "Never"
        Service = "awx"
        Management = "terraform"
    }
}

resource "aws_instance" "awx" {
    ami = data.aws_ami.RHEL.id
    instance_type = "t2.medium"

    network_interface {
        network_interface_id = aws_network_interface.awx-interface.id
        device_index         = 0
    }

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

resource "aws_eip" "awx-ip" {
  instance = aws_instance.awx.id
  vpc      = true

  tags = {
        Name = "awx elastic IP"
        Cluster = "none"
        Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
        Environment = "dev"
        Creator = "terraform"
        Expires = "Never"
        Service = "awx"
        Management = "terraform"
    }
}

# Create a new security group for AWX
resource "aws_security_group" "allow_awx_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.awx.id

  ingress {
    description = "SSH to VPN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["65.189.48.218/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_awx_ssh"
    Cluster = "none"
    Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
    Environment = "dev"
    Creator = "terraform"
    Expires = "Never"
    Service = "ssh"
    Management = "terraform"
  }
}