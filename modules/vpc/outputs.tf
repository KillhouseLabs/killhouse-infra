output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "app_security_group_id" {
  description = "App EC2 security group ID"
  value       = aws_security_group.app.id
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}
