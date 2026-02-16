variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "admin_cidr" {
  description = "CIDR block for admin SSH access (empty to disable)"
  type        = string
  default     = ""
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC Endpoints (ECR, Secrets Manager, CloudWatch Logs, S3)"
  type        = bool
  default     = true
}
