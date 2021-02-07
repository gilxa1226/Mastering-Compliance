
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

module "networking" {
    source = "./modules/networking"
    namespace = var.namespace
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
