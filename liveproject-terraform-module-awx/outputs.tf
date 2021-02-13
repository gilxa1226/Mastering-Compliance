output "server_ip" {
  value       = aws_instance.awx-instance.public_ip
  description = "Display the IPv4 Public IP of the EC2 server running AWX."
}
