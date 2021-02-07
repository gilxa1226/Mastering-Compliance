data "aws_availability_zones" "available" {}

module "vpc" {
    source                              = "terraform-aws-modules/vpc/aws"
    version                             = "2.5.0"
    name                                = "${var.namespace}-vpc"
    cidr                                = "10.0.0.0/16"
    azs                                 = data.aws_availability_zones.available.names
    private_subnets                     = ["10.0.1.0/24"]
    public_subnets                      = ["10.0.101.0/24"]
    assign_generated_ipv6_cidr_block    = true
    create_database_subnet_group        = false
    enable_nat_gateway                  = true
    single_nat_gateway                  = true

    tags = {
        Name = "${var.namespace}-vpc"
        Cluster = "none"
        Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
        Environment = "dev"
        Creator = "terraform"
        Expires = "Never"
        Service = "vpc"
        Management = "terraform"
    }
}

# Create a new security group for AWX
resource "aws_security_group" "awx_sg" {
  name        = "${var.namespace}-sg"
  description = "AWX security group"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.namespace}-sg"
    Cluster = "none"
    Project = "Mastering Compliance with Ansible, Terraform, and OpenSCAP"
    Environment = "dev"
    Creator = "terraform"
    Expires = "Never"
    Service = "secuirty group"
    Management = "terraform"
  }
}

resource "aws_security_group_rule" "ssh-ingress" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = [module.vpc.public_subnets]
    security_group_id = aws_security_group.awx_sg.id
}