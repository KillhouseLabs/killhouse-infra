output "instance_id" {
  description = "App EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "App Elastic IP (static)"
  value       = aws_eip.app.public_ip
}

output "private_ip" {
  description = "App EC2 private IP"
  value       = aws_instance.app.private_ip
}
