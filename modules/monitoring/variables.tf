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

variable "app_instance_id" {
  description = "App EC2 instance ID"
  type        = string
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
