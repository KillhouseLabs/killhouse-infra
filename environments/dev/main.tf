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

  # Uncomment to use S3 backend for state storage
  # backend "s3" {
  #   bucket         = "killhouse-terraform-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   encrypt        = true
  #   dynamodb_table = "killhouse-terraform-lock"
  # }
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

  project            = local.project
  environment        = local.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  admin_cidr         = var.admin_cidr
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

module "alb" {
  source = "../../modules/alb"

  project                   = local.project
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  alb_security_group_id     = module.vpc.alb_security_group_id
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  route53_zone_id           = var.route53_zone_id
}

module "ec2_agent" {
  source = "../../modules/ec2_agent"

  project                   = local.project
  environment               = local.environment
  region                    = local.region
  private_subnet_id         = module.vpc.private_subnet_ids[0]
  agent_security_group_id   = module.vpc.agent_security_group_id
  instance_type             = var.exploit_agent_instance_type
  ecr_registry_url          = module.ecr.registry_url
  secret_arns               = module.secrets.all_secret_arns
  openai_api_key_secret_arn = module.secrets.openai_api_key_arn
  supabase_url_secret_arn   = module.secrets.supabase_url_arn
  supabase_key_secret_arn   = module.secrets.supabase_key_arn
}

module "ecs" {
  source = "../../modules/ecs"

  project               = local.project
  environment           = local.environment
  region                = local.region
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.vpc.ecs_security_group_id
  use_spot              = var.use_fargate_spot

  # Web Client
  web_client_image            = module.ecr.web_client_repository_url
  web_client_image_tag        = var.web_client_image_tag
  web_client_cpu              = var.web_client_cpu
  web_client_memory           = var.web_client_memory
  web_client_desired_count    = var.web_client_desired_count
  web_client_target_group_arn = module.alb.web_client_target_group_arn

  # Scanner API
  scanner_api_image            = module.ecr.scanner_api_repository_url
  scanner_api_image_tag        = var.scanner_api_image_tag
  scanner_api_cpu              = var.scanner_api_cpu
  scanner_api_memory           = var.scanner_api_memory
  scanner_api_desired_count    = var.scanner_api_desired_count
  scanner_api_target_group_arn = module.alb.scanner_api_target_group_arn
  exploit_agent_private_ip     = module.ec2_agent.private_ip

  # Secrets
  secret_arns                     = module.secrets.all_secret_arns
  database_url_secret_arn         = module.secrets.database_url_arn
  direct_url_secret_arn           = module.secrets.direct_url_arn
  auth_secret_arn                 = module.secrets.auth_secret_arn
  auth_url_secret_arn             = module.secrets.auth_url_arn
  github_client_id_secret_arn     = module.secrets.github_client_id_arn
  github_client_secret_secret_arn = module.secrets.github_client_secret_arn
  portone_imp_code_secret_arn     = module.secrets.portone_imp_code_arn
  openai_api_key_secret_arn       = module.secrets.openai_api_key_arn
  supabase_url_secret_arn         = module.secrets.supabase_url_arn
  supabase_key_secret_arn         = module.secrets.supabase_key_arn
}

module "monitoring" {
  source = "../../modules/monitoring"

  project                   = local.project
  environment               = local.environment
  region                    = local.region
  alb_arn_suffix            = replace(module.alb.alb_arn, "/.*:loadbalancer\\//", "")
  ecs_cluster_name          = module.ecs.cluster_name
  ecs_service_names         = ["web-client", "scanner-api"]
  exploit_agent_instance_id = module.ec2_agent.instance_id
  create_sns_topic          = var.create_alarm_sns_topic
  alarm_email               = var.alarm_email
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "ecr_registry_url" {
  description = "ECR registry URL"
  value       = module.ecr.registry_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "exploit_agent_private_ip" {
  description = "Exploit Agent private IP"
  value       = module.ec2_agent.private_ip
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP (for allowlisting)"
  value       = module.vpc.nat_gateway_ip
}
