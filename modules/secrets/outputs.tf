# -----------------------------------------------------------------------------
# Secret ARNs
# -----------------------------------------------------------------------------

output "database_url_arn" {
  description = "DATABASE_URL secret ARN"
  value       = aws_secretsmanager_secret.database_url.arn
}

output "direct_url_arn" {
  description = "DIRECT_URL secret ARN"
  value       = aws_secretsmanager_secret.direct_url.arn
}

output "auth_secret_arn" {
  description = "AUTH_SECRET secret ARN"
  value       = aws_secretsmanager_secret.auth_secret.arn
}

output "auth_url_arn" {
  description = "AUTH_URL secret ARN"
  value       = aws_secretsmanager_secret.auth_url.arn
}

output "github_client_id_arn" {
  description = "GITHUB_CLIENT_ID secret ARN"
  value       = aws_secretsmanager_secret.github_client_id.arn
}

output "github_client_secret_arn" {
  description = "GITHUB_CLIENT_SECRET secret ARN"
  value       = aws_secretsmanager_secret.github_client_secret.arn
}

output "gitlab_client_id_arn" {
  description = "GITLAB_CLIENT_ID secret ARN"
  value       = aws_secretsmanager_secret.gitlab_client_id.arn
}

output "gitlab_client_secret_arn" {
  description = "GITLAB_CLIENT_SECRET secret ARN"
  value       = aws_secretsmanager_secret.gitlab_client_secret.arn
}

output "google_client_id_arn" {
  description = "GOOGLE_CLIENT_ID secret ARN"
  value       = aws_secretsmanager_secret.google_client_id.arn
}

output "google_client_secret_arn" {
  description = "GOOGLE_CLIENT_SECRET secret ARN"
  value       = aws_secretsmanager_secret.google_client_secret.arn
}

output "portone_imp_code_arn" {
  description = "PORTONE_IMP_CODE secret ARN"
  value       = aws_secretsmanager_secret.portone_imp_code.arn
}

output "portone_channel_key_arn" {
  description = "PORTONE_CHANNEL_KEY secret ARN"
  value       = aws_secretsmanager_secret.portone_channel_key.arn
}

output "portone_api_key_arn" {
  description = "PORTONE_API_KEY secret ARN"
  value       = aws_secretsmanager_secret.portone_api_key.arn
}

output "portone_api_secret_arn" {
  description = "PORTONE_API_SECRET secret ARN"
  value       = aws_secretsmanager_secret.portone_api_secret.arn
}

output "openai_api_key_arn" {
  description = "OPENAI_API_KEY secret ARN"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "supabase_url_arn" {
  description = "SUPABASE_URL secret ARN"
  value       = aws_secretsmanager_secret.supabase_url.arn
}

output "supabase_key_arn" {
  description = "SUPABASE_KEY secret ARN"
  value       = aws_secretsmanager_secret.supabase_key.arn
}

# All secret ARNs for IAM policies
output "all_secret_arns" {
  description = "List of all secret ARNs"
  value = [
    aws_secretsmanager_secret.database_url.arn,
    aws_secretsmanager_secret.direct_url.arn,
    aws_secretsmanager_secret.auth_secret.arn,
    aws_secretsmanager_secret.auth_url.arn,
    aws_secretsmanager_secret.github_client_id.arn,
    aws_secretsmanager_secret.github_client_secret.arn,
    aws_secretsmanager_secret.gitlab_client_id.arn,
    aws_secretsmanager_secret.gitlab_client_secret.arn,
    aws_secretsmanager_secret.google_client_id.arn,
    aws_secretsmanager_secret.google_client_secret.arn,
    aws_secretsmanager_secret.portone_imp_code.arn,
    aws_secretsmanager_secret.portone_channel_key.arn,
    aws_secretsmanager_secret.portone_api_key.arn,
    aws_secretsmanager_secret.portone_api_secret.arn,
    aws_secretsmanager_secret.openai_api_key.arn,
    aws_secretsmanager_secret.supabase_url.arn,
    aws_secretsmanager_secret.supabase_key.arn,
  ]
}
