output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.exploit_agent.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.exploit_agent.private_ip
}

output "instance_role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.agent.arn
}
