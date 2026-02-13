output "web_client_repository_url" {
  description = "ECR repository URL for web-client"
  value       = aws_ecr_repository.web_client.repository_url
}

output "scanner_api_repository_url" {
  description = "ECR repository URL for scanner-api"
  value       = aws_ecr_repository.scanner_api.repository_url
}

output "exploit_agent_repository_url" {
  description = "ECR repository URL for exploit-agent"
  value       = aws_ecr_repository.exploit_agent.repository_url
}

output "exploit_sandbox_repository_url" {
  description = "ECR repository URL for exploit-sandbox"
  value       = aws_ecr_repository.exploit_sandbox.repository_url
}

output "registry_url" {
  description = "ECR registry URL (account.dkr.ecr.region.amazonaws.com)"
  value       = split("/", aws_ecr_repository.web_client.repository_url)[0]
}
