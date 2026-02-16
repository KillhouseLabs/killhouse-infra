variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the app EC2 instance"
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID for the app EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 80
}

variable "domain_name" {
  description = "Domain name for Caddy TLS (e.g., dev.killhouse.io)"
  type        = string
}

variable "acme_email" {
  description = "Email for Let's Encrypt ACME registration"
  type        = string
}

variable "ecr_registry_url" {
  description = "ECR registry URL (account.dkr.ecr.region.amazonaws.com)"
  type        = string
}

variable "secret_arns" {
  description = "List of all secret ARNs for IAM policy"
  type        = list(string)
}

# Individual secret ARNs for user_data.sh
variable "database_url_secret_arn" {
  description = "Secrets Manager ARN for DATABASE_URL"
  type        = string
}

variable "direct_url_secret_arn" {
  description = "Secrets Manager ARN for DIRECT_URL"
  type        = string
}

variable "auth_secret_arn" {
  description = "Secrets Manager ARN for AUTH_SECRET"
  type        = string
}

variable "auth_url_secret_arn" {
  description = "Secrets Manager ARN for AUTH_URL"
  type        = string
}

variable "github_client_id_secret_arn" {
  description = "Secrets Manager ARN for GITHUB_CLIENT_ID"
  type        = string
}

variable "github_client_secret_secret_arn" {
  description = "Secrets Manager ARN for GITHUB_CLIENT_SECRET"
  type        = string
}

variable "portone_imp_code_secret_arn" {
  description = "Secrets Manager ARN for NEXT_PUBLIC_IMP_CODE"
  type        = string
}

variable "openai_api_key_secret_arn" {
  description = "Secrets Manager ARN for OPENAI_API_KEY"
  type        = string
}

variable "supabase_url_secret_arn" {
  description = "Secrets Manager ARN for SUPABASE_URL"
  type        = string
}

variable "supabase_key_secret_arn" {
  description = "Secrets Manager ARN for SUPABASE_KEY"
  type        = string
}

variable "google_client_id_secret_arn" {
  description = "Secrets Manager ARN for GOOGLE_CLIENT_ID"
  type        = string
}

variable "google_client_secret_secret_arn" {
  description = "Secrets Manager ARN for GOOGLE_CLIENT_SECRET"
  type        = string
}

variable "gitlab_client_id_secret_arn" {
  description = "Secrets Manager ARN for GITLAB_CLIENT_ID"
  type        = string
}

variable "gitlab_client_secret_secret_arn" {
  description = "Secrets Manager ARN for GITLAB_CLIENT_SECRET"
  type        = string
}

variable "portone_channel_key_secret_arn" {
  description = "Secrets Manager ARN for NEXT_PUBLIC_PORTONE_CHANNEL_KEY"
  type        = string
}

variable "portone_api_key_secret_arn" {
  description = "Secrets Manager ARN for PORTONE_REST_API_KEY"
  type        = string
}

variable "portone_api_secret_secret_arn" {
  description = "Secrets Manager ARN for PORTONE_REST_API_SECRET"
  type        = string
}

variable "scanner_api_key_secret_arn" {
  description = "Secrets Manager ARN for SCANNER_API_KEY"
  type        = string
}

variable "enable_ssm" {
  description = "Enable SSM Session Manager for remote access"
  type        = bool
  default     = true
}
