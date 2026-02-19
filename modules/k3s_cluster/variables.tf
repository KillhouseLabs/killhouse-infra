variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy k3s cluster into"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for k3s nodes (private subnets recommended)"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for k3s server nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_count" {
  description = "Number of k3s server nodes (must be odd for etcd quorum)"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count % 2 == 1
    error_message = "node_count must be odd for etcd quorum."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 80
}

variable "ecr_registry_url" {
  description = "ECR registry URL for pulling images"
  type        = string
}

variable "secret_arns" {
  description = "List of Secrets Manager ARNs for IAM policy"
  type        = list(string)
}

variable "k3s_version" {
  description = "k3s version to install"
  type        = string
  default     = "v1.31.4+k3s1"
}

variable "k3s_token" {
  description = "Shared secret for k3s cluster join (stored in Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for NLB (k3s API endpoint)"
  type        = list(string)
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (empty to disable)"
  type        = string
  default     = ""
}
