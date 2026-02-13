# Killhouse Infrastructure

AWS infrastructure as code for KILLHOUSE security vulnerability scanning platform.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS VPC                                  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Public Subnet                             ││
│  │  ┌─────────────┐                                            ││
│  │  │     ALB     │  ← ACM Certificate (HTTPS)                 ││
│  │  └──────┬──────┘                                            ││
│  └─────────┼───────────────────────────────────────────────────┘│
│            │                                                     │
│  ┌─────────┼───────────────────────────────────────────────────┐│
│  │         │           Private Subnet                           ││
│  │         ▼                                                    ││
│  │  ┌─────────────────────────────────────────────────────┐    ││
│  │  │                 ECS Cluster                          │    ││
│  │  │  ┌──────────────┐  ┌──────────────┐                 │    ││
│  │  │  │ web-client   │  │ scanner-api  │                 │    ││
│  │  │  │ (Fargate)    │  │ (Fargate)    │                 │    ││
│  │  │  └──────────────┘  └──────┬───────┘                 │    ││
│  │  │                           │                          │    ││
│  │  │                    ┌──────▼───────┐                 │    ││
│  │  │                    │ exploit-agent│                 │    ││
│  │  │                    │ (EC2 + DinD) │                 │    ││
│  │  │                    └──────────────┘                 │    ││
│  │  └──────────────────────────────────────────────────────┘    ││
│  │  ┌──────────────┐                                           ││
│  │  │  NAT Gateway │ → OpenAI, Supabase                        ││
│  │  └──────────────┘                                           ││
│  └──────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.6.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- Domain name (for ACM certificate)

## Quick Start

```bash
# 1. Initialize Terraform
cd environments/dev
terraform init

# 2. Set your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Plan
terraform plan

# 4. Apply
terraform apply
```

## Directory Structure

```
.
├── environments/
│   ├── dev/              # Development environment
│   └── prod/             # Production environment
├── modules/
│   ├── vpc/              # VPC, Subnets, Security Groups
│   ├── ecs/              # ECS Cluster, Services, Tasks
│   ├── alb/              # Application Load Balancer
│   ├── ec2_agent/        # EC2 for Exploit Agent (DinD)
│   ├── ecr/              # Container Registry
│   ├── secrets/          # Secrets Manager
│   └── monitoring/       # CloudWatch, Alarms
└── scripts/
    └── deploy.sh         # Deployment helper
```

## Modules

| Module | Description |
|--------|-------------|
| `vpc` | VPC, public/private subnets, NAT Gateway, security groups |
| `ecs` | ECS Fargate cluster, web-client and scanner-api services |
| `alb` | Application Load Balancer with HTTPS, path-based routing |
| `ec2_agent` | EC2 instance for exploit-agent with Docker-in-Docker |
| `ecr` | ECR repositories for container images |
| `secrets` | AWS Secrets Manager for sensitive configuration |
| `monitoring` | CloudWatch log groups and alarms |

## Security Groups

| Security Group | Inbound | Outbound |
|----------------|---------|----------|
| `alb-sg` | 80, 443 from 0.0.0.0/0 | All to ECS |
| `ecs-sg` | 3000, 8080 from ALB | 443 (OpenAI, Supabase) |
| `agent-sg` | 8081 from ECS | 443 (OpenAI only) |

## Cost Estimation

| Resource | Monthly Cost |
|----------|--------------|
| ALB | ~$20 |
| NAT Gateway | ~$35 |
| ECS Fargate (2 services) | ~$45 |
| EC2 t3.medium | ~$30 |
| Others | ~$20 |
| **Total** | **~$150** |

## Environment Variables

Set these secrets in AWS Secrets Manager after deployment:

- `killhouse/openai-api-key`
- `killhouse/supabase-url`
- `killhouse/supabase-key`
- `killhouse/auth-secret`
- `killhouse/database-url`

## License

Private - All rights reserved
