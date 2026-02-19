output "k3s_api_endpoint" {
  description = "k3s API server endpoint (NLB DNS)"
  value       = "https://${aws_lb.k3s_api.dns_name}:6443"
}

output "k3s_api_dns" {
  description = "k3s API NLB DNS name"
  value       = aws_lb.k3s_api.dns_name
}

output "k3s_node_ids" {
  description = "List of k3s node EC2 instance IDs"
  value       = aws_instance.k3s_server[*].id
}

output "k3s_node_private_ips" {
  description = "List of k3s node private IPs"
  value       = aws_instance.k3s_server[*].private_ip
}

output "k3s_security_group_id" {
  description = "k3s cluster security group ID"
  value       = aws_security_group.k3s.id
}

output "k3s_init_node_id" {
  description = "EC2 instance ID of the k3s init node (for SSM kubeconfig retrieval)"
  value       = aws_instance.k3s_server[0].id
}
