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

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_names" {
  description = "List of ECS service names to monitor"
  type        = list(string)
  default     = ["web-client", "scanner-api"]
}

variable "exploit_agent_instance_id" {
  description = "EC2 instance ID for exploit agent"
  type        = string
  default     = ""
}

variable "create_sns_topic" {
  description = "Create SNS topic for alarms"
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "Existing SNS topic ARN for alarms"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}
