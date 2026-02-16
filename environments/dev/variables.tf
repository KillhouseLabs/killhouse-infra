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

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC Endpoints (adds ~$28/mo)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Domain & TLS
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Primary domain name for Caddy TLS"
  type        = string
}

variable "acme_email" {
  description = "Email for Let's Encrypt ACME registration"
  type        = string
}

# -----------------------------------------------------------------------------
# EC2 - App
# -----------------------------------------------------------------------------

variable "app_instance_type" {
  description = "EC2 instance type for app server"
  type        = string
  default     = "t3.large"
}

# -----------------------------------------------------------------------------
# GitHub OIDC
# -----------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organization or user name for OIDC trust"
  type        = string
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
