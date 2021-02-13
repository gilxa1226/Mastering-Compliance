
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

# Create a VPC
resource "aws_vpc" "awx-vpc" {
    cidr_block  = "10.0.0.0/16"
    tags        = var.tags
}

# Create an internet gateway for AWX
resource "aws_internet_gateway" "awx-internet-gateway" {
    vpc_id = aws_vpc.awx-vpc.allocation_id
    tags = var.tags
}

# Create a custom route table for AWX
resource "aws_route_table" "awx-route-table" {
  vpc_id = aws_vpc.awx-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.awx-internet-gateway.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.awx-internet-gateway.id
  }
  tags = var.tags
}

# Create a public subnet
resource "aws_subnet" "awx-public-subnet" {
  vpc_id     = aws_vpc.awx-vpc.id
  cidr_block = var.public_subnet_prefix.cidr_block
  tags = merge(
    var.tags,
    {
      Name = var.public_subnet_prefix.name
    },
  )
}

# Associate a public subnet with the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.awx-public-subnet.id
  route_table_id = aws_route_table.awx-route-table.id
}

# Create an elastic IP for NAT gateway (step 8.)
resource "aws_eip" "eip" {
  vpc  = true
  tags = var.tags
}

# Create a NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.awx-public-subnet.id
  tags          = var.tags
}

# Create a custom route table for AWX
resource "aws_route_table" "awx-route-table-nat" {
  vpc_id = aws_vpc.awx-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = var.tags
}

# 10. Create a private subnet
resource "aws_subnet" "awx-private-subnet" {
  vpc_id     = aws_vpc.awx-vpc.id
  cidr_block = var.private_subnet_prefix.cidr_block
  tags = merge(
    var.tags,
    {
      Name = var.private_subnet_prefix.name
    },
  )
}

# Associate a private subnet with the route table (step 10.)
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.awx-private-subnet.id
  route_table_id = aws_route_table.awx-route-table-nat.id
}

# Create a security group to allow ports 22, 80 from your home address
resource "aws_security_group" "allow_web_and_ssh" {
  name        = "allow_web_and_ssh"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.awx-vpc.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.home_ip
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.home_ip
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

# Create a RHEL8 server and install AWX on it
resource "aws_instance" "awx-instance" {
  ami                         = data.aws_ami.RHEL.id
  instance_type               = "t2.medium"
  key_name                    = var.ssh_keypair
  subnet_id                   = aws_subnet.awx-public-subnet.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.allow_web_and_ssh.id]
  user_data                   = <<-EOF
    #!/bin/bash
    # Sun Nov 1 11:21:20 UTC 2020
    # User data is run by user 'root', logs are located in /var/log/cloud-init-output.log on the EC2 machine.
    # 1. Add an EPEL repository
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    # 2. Add a Docker Community Edition repository
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    # 3. Install Docker Community Edition v19.03.13, Firewalld v0.8.0, Ansible v2.9.14 and Git v2.18.4
    dnf -y install docker-ce firewalld ansible git
    # 4. Add used ec2-user to the docker group - so the user can use Docker
    usermod -aG docker ec2-user
    # 5. Reload a Linux user's group assignments without logging out
    su - ec2-user
    # 6. Start Docker daemon and enable it on boot
    systemctl enable docker --now
    # 7. Disable Firewalld on boot. It is only required to be installed by Docker CE, but does not have to run
    systemctl disable firewalld
    # 8. Install docker-compose Ansible dependency as ec2-user
    sudo -u ec2-user pip3 install docker-compose --user
    # 9. Clone AWX version 13 from Github as ec2-user
    sudo -u ec2-user git clone -b 13.0.0 https://github.com/ansible/awx.git /home/ec2-user/awx
    # 10. Create a minimal variable file that Ansible installation playbook needs
    cat <<VEOF > /home/ec2-user/awx/installer/vars.yml
    admin_password: '0p2qbWvW3HFS'
    pg_password: 'x9p97ldwigtT'
    secret_key: '0QpsgYALr7BC'
    VEOF
    # 11. Run the installation Ansible playbook, this will take a few minutes
    sudo -u ec2-user ansible-playbook -i /home/ec2-user/awx/installer/inventory /home/ec2-user/awx/installer/install.yml -e @/home/ec2-user/awx/installer/vars.yml
    EOF
  tags                        = var.tags
}
