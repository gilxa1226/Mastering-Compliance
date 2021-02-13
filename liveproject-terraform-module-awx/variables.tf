variable "home_ip" {
  default = [
    "65.189.48.218/32",
  ]
  description = "IP addresses from where you will be accessing HTTP and SSH of the AWX server. Should be public IP of your development-node and from your home so you can open the web GUI."
}

variable "namespace" {
    description = "The project namespace to use for unique resource naming"
    type        = string
}

variable "ssh_keypair" {
    description = "Optional ssh keypair to use for EC2 instance"
    default     = "liveproject"
    type        = string
}

variable "region" {
    description = "AWS region"
    default     = "us-east-2"
    type        = string
}

variable "tags" {
  default = {
    Cluster     = "none"
    Creator     = "terraform"
    Environment = "dev"
    Expires     = "never"
    Management  = "liveproject"
    Name        = "awx"
    Project     = "liveproject"
    Service     = "awx"
  }
  description = "A label that you assign to an AWS resource(s)."
}

variable public_subnet_prefix {
  default = {
    name        = "awx-public"
    cidr_block  = "10.0.1.0/24"
    description = "CIDR block for the public subnet."
  }
}

variable private_subnet_prefix {
  default = {
    name        = "awx-private"
    cidr_block  = "10.0.2.0/24"
    description = "CIDR block for the private subnet."
  }
}