# -----------------------------------------------------------------------------
# Terraform Configuration
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "killhouse-terraform-state-935328470386"
    key            = "staging/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "killhouse-terraform-lock"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------

locals {
  project     = var.project
  environment = var.environment
  region      = var.region
}

# -----------------------------------------------------------------------------
# Modules
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  project              = local.project
  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  admin_cidr           = var.admin_cidr
  enable_flow_logs     = var.enable_flow_logs
  enable_vpc_endpoints = var.enable_vpc_endpoints
}

module "ecr" {
  source = "../../modules/ecr"

  project     = local.project
  environment = local.environment
}

module "secrets" {
  source = "../../modules/secrets"

  project     = local.project
  environment = local.environment
}

module "k3s_cluster" {
  source = "../../modules/k3s_cluster"

  project          = local.project
  environment      = local.environment
  region           = local.region
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_type    = var.k3s_instance_type
  node_count       = var.k3s_node_count
  ecr_registry_url = module.ecr.registry_url
  secret_arns      = module.secrets.all_secret_arns
  k3s_token        = var.k3s_token
}

module "oidc" {
  source = "../../modules/oidc"

  project           = local.project
  environment       = local.environment
  github_org        = var.github_org
  state_bucket_name = "killhouse-terraform-state-935328470386"
  lock_table_name   = "killhouse-terraform-lock"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "k3s_api_endpoint" {
  description = "k3s API server endpoint (NLB)"
  value       = module.k3s_cluster.k3s_api_endpoint
}

output "k3s_api_dns" {
  description = "k3s API NLB DNS name"
  value       = module.k3s_cluster.k3s_api_dns
}

output "k3s_node_ids" {
  description = "k3s node EC2 instance IDs (for SSM sessions)"
  value       = module.k3s_cluster.k3s_node_ids
}

output "k3s_init_node_id" {
  description = "k3s init node instance ID (for kubeconfig retrieval)"
  value       = module.k3s_cluster.k3s_init_node_id
}

output "ecr_registry_url" {
  description = "ECR registry URL"
  value       = module.ecr.registry_url
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC role ARN"
  value       = module.oidc.github_actions_role_arn
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP"
  value       = module.vpc.nat_gateway_ip
}
