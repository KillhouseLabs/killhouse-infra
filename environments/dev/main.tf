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
    key            = "dev/terraform.tfstate"
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

module "ec2_app" {
  source = "../../modules/ec2_app"

  project               = local.project
  environment           = local.environment
  region                = local.region
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  app_security_group_id = module.vpc.app_security_group_id
  instance_type         = var.app_instance_type
  domain_name           = var.domain_name
  monitor_domain_name   = var.monitor_domain_name
  acme_email            = var.acme_email
  ecr_registry_url      = module.ecr.registry_url

  # Secrets
  secret_arns = module.secrets.all_secret_arns

  # Database
  database_url_secret_arn = module.secrets.database_url_arn
  direct_url_secret_arn   = module.secrets.direct_url_arn

  # Auth
  auth_secret_arn     = module.secrets.auth_secret_arn
  auth_url_secret_arn = module.secrets.auth_url_arn

  # OAuth
  github_client_id_secret_arn     = module.secrets.github_client_id_arn
  github_client_secret_secret_arn = module.secrets.github_client_secret_arn
  google_client_id_secret_arn     = module.secrets.google_client_id_arn
  google_client_secret_secret_arn = module.secrets.google_client_secret_arn
  gitlab_client_id_secret_arn     = module.secrets.gitlab_client_id_arn
  gitlab_client_secret_secret_arn = module.secrets.gitlab_client_secret_arn

  # Payment
  portone_imp_code_secret_arn    = module.secrets.portone_imp_code_arn
  portone_channel_key_secret_arn = module.secrets.portone_channel_key_arn
  portone_api_key_secret_arn     = module.secrets.portone_api_key_arn
  portone_api_secret_secret_arn  = module.secrets.portone_api_secret_arn

  # External services
  openai_api_key_secret_arn  = module.secrets.openai_api_key_arn
  supabase_url_secret_arn    = module.secrets.supabase_url_arn
  supabase_key_secret_arn    = module.secrets.supabase_key_arn
  scanner_api_key_secret_arn = module.secrets.scanner_api_key_arn

  # LGTM Monitoring
  grafana_admin_password = var.grafana_admin_password
  smtp_user              = var.smtp_user
  smtp_password          = var.smtp_password
}

module "oidc" {
  source = "../../modules/oidc"

  project           = local.project
  environment       = local.environment
  github_org        = var.github_org
  state_bucket_name = "killhouse-terraform-state-935328470386"
  lock_table_name   = "killhouse-terraform-lock"
}

module "monitoring" {
  source = "../../modules/monitoring"

  project          = local.project
  environment      = local.environment
  region           = local.region
  app_instance_id  = module.ec2_app.instance_id
  create_sns_topic = var.create_alarm_sns_topic
  alarm_email      = var.alarm_email
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "app_public_ip" {
  description = "App EC2 Elastic IP (set DNS A record to this)"
  value       = module.ec2_app.public_ip
}

output "app_private_ip" {
  description = "App EC2 private IP"
  value       = module.ec2_app.private_ip
}

output "app_instance_id" {
  description = "App EC2 instance ID (for SSM sessions)"
  value       = module.ec2_app.instance_id
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
  description = "NAT Gateway public IP (for allowlisting)"
  value       = module.vpc.nat_gateway_ip
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "https://${var.monitor_domain_name}/"
}
