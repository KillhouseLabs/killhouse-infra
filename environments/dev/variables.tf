# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name"
  type        = string
  default     = "killhouse"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "admin_cidr" {
  description = "Admin CIDR for SSH access"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Domain & SSL
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (empty to skip DNS setup)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# ECS - Web Client
# -----------------------------------------------------------------------------

variable "web_client_image_tag" {
  description = "Web client Docker image tag"
  type        = string
  default     = "latest"
}

variable "web_client_cpu" {
  description = "Web client CPU units"
  type        = number
  default     = 512
}

variable "web_client_memory" {
  description = "Web client memory in MB"
  type        = number
  default     = 1024
}

variable "web_client_desired_count" {
  description = "Web client desired task count"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# ECS - Scanner API
# -----------------------------------------------------------------------------

variable "scanner_api_image_tag" {
  description = "Scanner API Docker image tag"
  type        = string
  default     = "latest"
}

variable "scanner_api_cpu" {
  description = "Scanner API CPU units"
  type        = number
  default     = 1024
}

variable "scanner_api_memory" {
  description = "Scanner API memory in MB"
  type        = number
  default     = 2048
}

variable "scanner_api_desired_count" {
  description = "Scanner API desired task count"
  type        = number
  default     = 1
}

variable "use_fargate_spot" {
  description = "Use Fargate Spot for cost savings"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# EC2 - Exploit Agent
# -----------------------------------------------------------------------------

variable "exploit_agent_instance_type" {
  description = "EC2 instance type for exploit agent"
  type        = string
  default     = "t3.medium"
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "create_alarm_sns_topic" {
  description = "Create SNS topic for alarms"
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email for alarm notifications"
  type        = string
  default     = ""
}
