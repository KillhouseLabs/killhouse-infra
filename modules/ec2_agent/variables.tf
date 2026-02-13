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

variable "private_subnet_id" {
  description = "Private subnet ID for EC2 instance"
  type        = string
}

variable "agent_security_group_id" {
  description = "Security group ID for exploit agent"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "ecr_registry_url" {
  description = "ECR registry URL"
  type        = string
}

variable "exploit_agent_image" {
  description = "ECR image name for exploit-agent"
  type        = string
  default     = "killhouse/exploit-agent"
}

variable "exploit_sandbox_image" {
  description = "ECR image name for exploit-sandbox"
  type        = string
  default     = "killhouse/exploit-sandbox"
}

variable "secret_arns" {
  description = "List of secret ARNs for EC2 role"
  type        = list(string)
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

variable "enable_ssm" {
  description = "Enable SSM for debugging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}
