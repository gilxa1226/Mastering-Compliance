output "vpc" {
    value = module.vpc
}

output "sg" {
    value = aws_security_group.awx_sg
}