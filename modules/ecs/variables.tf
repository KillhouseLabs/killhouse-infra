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

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS services"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "use_spot" {
  description = "Use Fargate Spot for cost savings"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Web Client Configuration
# -----------------------------------------------------------------------------

variable "web_client_image" {
  description = "Docker image for web-client"
  type        = string
}

variable "web_client_image_tag" {
  description = "Docker image tag for web-client"
  type        = string
  default     = "latest"
}

variable "web_client_cpu" {
  description = "CPU units for web-client (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "web_client_memory" {
  description = "Memory for web-client in MB"
  type        = number
  default     = 1024
}

variable "web_client_desired_count" {
  description = "Desired number of web-client tasks"
  type        = number
  default     = 1
}

variable "web_client_target_group_arn" {
  description = "ALB target group ARN for web-client"
  type        = string
}

# -----------------------------------------------------------------------------
# Scanner API Configuration
# -----------------------------------------------------------------------------

variable "scanner_api_image" {
  description = "Docker image for scanner-api"
  type        = string
}

variable "scanner_api_image_tag" {
  description = "Docker image tag for scanner-api"
  type        = string
  default     = "latest"
}

variable "scanner_api_cpu" {
  description = "CPU units for scanner-api (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "scanner_api_memory" {
  description = "Memory for scanner-api in MB"
  type        = number
  default     = 2048
}

variable "scanner_api_desired_count" {
  description = "Desired number of scanner-api tasks"
  type        = number
  default     = 1
}

variable "scanner_api_target_group_arn" {
  description = "ALB target group ARN for scanner-api"
  type        = string
}

variable "exploit_agent_private_ip" {
  description = "Private IP of exploit-agent EC2 instance"
  type        = string
}

# -----------------------------------------------------------------------------
# Secrets ARNs
# -----------------------------------------------------------------------------

variable "secret_arns" {
  description = "List of secret ARNs for ECS execution role"
  type        = list(string)
}

variable "database_url_secret_arn" {
  description = "ARN of DATABASE_URL secret"
  type        = string
}

variable "direct_url_secret_arn" {
  description = "ARN of DIRECT_URL secret"
  type        = string
}

variable "auth_secret_arn" {
  description = "ARN of AUTH_SECRET secret"
  type        = string
}

variable "auth_url_secret_arn" {
  description = "ARN of AUTH_URL secret"
  type        = string
}

variable "github_client_id_secret_arn" {
  description = "ARN of GITHUB_CLIENT_ID secret"
  type        = string
}

variable "github_client_secret_secret_arn" {
  description = "ARN of GITHUB_CLIENT_SECRET secret"
  type        = string
}

variable "portone_imp_code_secret_arn" {
  description = "ARN of NEXT_PUBLIC_IMP_CODE secret"
  type        = string
}

variable "openai_api_key_secret_arn" {
  description = "ARN of OPENAI_API_KEY secret"
  type        = string
}

variable "supabase_url_secret_arn" {
  description = "ARN of SUPABASE_URL secret"
  type        = string
}

variable "supabase_key_secret_arn" {
  description = "ARN of SUPABASE_KEY secret"
  type        = string
}
