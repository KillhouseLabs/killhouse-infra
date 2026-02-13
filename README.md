# Killhouse Infrastructure

AWS infrastructure as code for KILLHOUSE security vulnerability scanning platform.

## 목차

- [아키텍처](#아키텍처)
- [사전 요구사항](#사전-요구사항)
- [빠른 시작](#빠른-시작)
- [상세 사용법](#상세-사용법)
  - [로컬 배포](#로컬-배포)
  - [CI/CD 배포](#cicd-배포)
  - [Docker 이미지 빌드](#docker-이미지-빌드)
- [설정 가이드](#설정-가이드)
- [디렉토리 구조](#디렉토리-구조)
- [모듈 설명](#모듈-설명)
- [보안 그룹](#보안-그룹)
- [비용 추정](#비용-추정)
- [문제 해결](#문제-해결)

## 아키텍처

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

## 사전 요구사항

| 도구 | 버전 | 설치 방법 |
|------|------|----------|
| [Terraform](https://www.terraform.io/downloads) | >= 1.6.0 | `brew install terraform` |
| [AWS CLI](https://aws.amazon.com/cli/) | v2 | `brew install awscli` |
| [Docker](https://www.docker.com/) | 최신 | Docker Desktop 설치 |

### AWS 자격 증명 설정

```bash
# AWS CLI 설정
aws configure

# 또는 환경 변수 사용
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-2"
```

### 필요한 AWS 권한

IAM 사용자에게 다음 권한이 필요합니다:
- `AmazonEC2FullAccess`
- `AmazonECS_FullAccess`
- `AmazonVPCFullAccess`
- `ElasticLoadBalancingFullAccess`
- `AmazonEC2ContainerRegistryFullAccess`
- `SecretsManagerReadWrite`
- `CloudWatchFullAccess`
- `AmazonSNSFullAccess`
- `AWSCertificateManagerFullAccess`

## 빠른 시작

```bash
# 1. 저장소 클론
git clone https://github.com/your-org/killhouse-infra.git
cd killhouse-infra

# 2. 환경 설정
cd environments/dev
cp terraform.tfvars.example terraform.tfvars

# 3. terraform.tfvars 편집 (아래 설정 가이드 참조)
vim terraform.tfvars

# 4. Terraform 초기화 및 배포
terraform init
terraform plan
terraform apply
```

## 상세 사용법

### 로컬 배포

#### deploy.sh 스크립트 사용

```bash
# 스크립트에 실행 권한 부여
chmod +x scripts/deploy.sh

# 사용법
./scripts/deploy.sh <environment> <action>

# 예시
./scripts/deploy.sh dev init      # Terraform 초기화
./scripts/deploy.sh dev plan      # 변경 사항 미리보기
./scripts/deploy.sh dev apply     # 인프라 배포
./scripts/deploy.sh dev output    # 출력 값 확인
./scripts/deploy.sh dev destroy   # 인프라 삭제 (주의!)
```

#### 수동 Terraform 실행

```bash
# 개발 환경
cd environments/dev

# Terraform 초기화 (최초 1회 또는 모듈 변경 시)
terraform init

# 업그레이드 포함 초기화
terraform init -upgrade

# 변경 사항 확인
terraform plan -out=tfplan

# 배포 실행
terraform apply tfplan

# 또는 직접 apply
terraform apply

# 특정 리소스만 배포
terraform apply -target=module.ecs

# 출력 값 확인
terraform output

# 상태 확인
terraform state list
```

### CI/CD 배포

GitHub Actions를 통해 자동화된 배포가 가능합니다.

#### Terraform 워크플로우 (.github/workflows/terraform.yml)

**트리거 조건:**
- `main` 브랜치에 push 시: 자동 apply
- Pull Request 생성 시: plan만 실행

**필요한 GitHub Secrets:**
```
AWS_ACCESS_KEY_ID      # AWS 액세스 키
AWS_SECRET_ACCESS_KEY  # AWS 시크릿 키
```

**워크플로우 단계:**
1. **Validate**: 코드 포맷 검사 및 모듈 유효성 검사
2. **Plan (PR)**: 변경 사항 미리보기
3. **Apply (main)**: 인프라 자동 배포

### Docker 이미지 빌드

GitHub Actions에서 수동으로 실행합니다.

```bash
# GitHub UI에서 Actions → Build and Push Docker Images → Run workflow
# 또는 gh CLI 사용
gh workflow run docker-build.yml \
  -f service=web-client \
  -f environment=dev
```

**빌드 가능한 서비스:**
| 서비스 | 설명 |
|--------|------|
| `web-client` | 프론트엔드 웹 애플리케이션 |
| `scanner-api` | 스캐너 API 서버 |
| `exploit-agent` | 익스플로잇 에이전트 |
| `exploit-sandbox` | 샌드박스 환경 |
| `all` | 모든 서비스 빌드 |

**ECS 서비스 수동 업데이트:**
```bash
# 클러스터 이름 확인
aws ecs list-clusters

# 서비스 강제 재배포
aws ecs update-service \
  --cluster killhouse-cluster \
  --service web-client \
  --force-new-deployment

aws ecs update-service \
  --cluster killhouse-cluster \
  --service scanner-api \
  --force-new-deployment
```

## 설정 가이드

### terraform.tfvars 설정

`environments/dev/terraform.tfvars.example`을 복사하여 수정합니다:

```hcl
# -----------------------------------------------------------------------------
# General - 프로젝트 기본 설정
# -----------------------------------------------------------------------------
project     = "killhouse"
environment = "dev"               # dev 또는 prod
region      = "ap-northeast-2"    # AWS 리전

# -----------------------------------------------------------------------------
# Network - 네트워크 설정
# -----------------------------------------------------------------------------
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
enable_nat_gateway = true         # 프라이빗 서브넷 외부 통신에 필요
admin_cidr         = "YOUR_IP/32" # SSH 접근을 허용할 IP (예: 123.45.67.89/32)

# -----------------------------------------------------------------------------
# Domain & SSL - 도메인 설정
# -----------------------------------------------------------------------------
domain_name               = "dev.killhouse.io"        # 주 도메인
subject_alternative_names = ["*.dev.killhouse.io"]    # 와일드카드 인증서
route53_zone_id           = ""    # Route53 호스팅 영역 ID (선택사항)

# -----------------------------------------------------------------------------
# ECS - Web Client 설정
# -----------------------------------------------------------------------------
web_client_image_tag     = "latest"
web_client_cpu           = 512    # vCPU 단위 (512 = 0.5 vCPU)
web_client_memory        = 1024   # MB 단위
web_client_desired_count = 1      # 원하는 태스크 수

# -----------------------------------------------------------------------------
# ECS - Scanner API 설정
# -----------------------------------------------------------------------------
scanner_api_image_tag     = "latest"
scanner_api_cpu           = 1024  # vCPU 단위 (1024 = 1 vCPU)
scanner_api_memory        = 2048  # MB 단위
scanner_api_desired_count = 1
use_fargate_spot          = true  # 비용 절감을 위한 스팟 인스턴스 사용

# -----------------------------------------------------------------------------
# EC2 - Exploit Agent 설정
# -----------------------------------------------------------------------------
exploit_agent_instance_type = "t3.medium"  # Docker-in-Docker를 위해 최소 t3.medium 권장

# -----------------------------------------------------------------------------
# Monitoring - 모니터링 설정
# -----------------------------------------------------------------------------
create_alarm_sns_topic = false    # SNS 알림 토픽 생성 여부
alarm_email            = ""       # 알림 수신 이메일
```

### AWS Secrets Manager 설정

배포 후 다음 시크릿을 AWS Secrets Manager에서 설정해야 합니다:

```bash
# OpenAI API 키
aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/openai-api-key \
  --secret-string "sk-..."

# Supabase URL
aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/supabase-url \
  --secret-string "https://xxx.supabase.co"

# Supabase 키
aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/supabase-key \
  --secret-string "eyJ..."

# Auth Secret (Next-Auth용)
aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/auth-secret \
  --secret-string "your-secret-key"

# Database URL
aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/database-url \
  --secret-string "postgresql://..."

# Direct URL (Prisma Migrate용)
aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/direct-url \
  --secret-string "postgresql://..."

# GitHub OAuth (선택사항)
aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/github-client-id \
  --secret-string "Iv1.xxx"

aws secretsmanager put-secret-value \
  --secret-id killhouse/dev/github-client-secret \
  --secret-string "xxx"
```

### 원격 State 설정 (선택사항)

팀 협업 시 S3 백엔드를 사용하여 상태를 공유합니다:

```bash
# S3 버킷 생성
aws s3 mb s3://killhouse-terraform-state --region ap-northeast-2

# DynamoDB 테이블 생성 (잠금용)
aws dynamodb create-table \
  --table-name killhouse-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

그 후 `environments/dev/main.tf`에서 backend 블록 주석을 해제합니다.

## 디렉토리 구조

```
.
├── .github/
│   └── workflows/
│       ├── terraform.yml      # Terraform CI/CD
│       └── docker-build.yml   # Docker 이미지 빌드
├── environments/
│   ├── dev/                   # 개발 환경
│   │   ├── main.tf           # 메인 설정 및 모듈 호출
│   │   ├── variables.tf      # 변수 정의
│   │   └── terraform.tfvars.example  # 예제 설정
│   └── prod/                  # 프로덕션 환경 (구조 동일)
├── modules/
│   ├── vpc/                   # VPC, 서브넷, 보안 그룹
│   ├── ecs/                   # ECS 클러스터, 서비스, 태스크
│   ├── alb/                   # Application Load Balancer
│   ├── ec2_agent/             # EC2 익스플로잇 에이전트
│   ├── ecr/                   # Container Registry
│   ├── secrets/               # Secrets Manager
│   └── monitoring/            # CloudWatch, 알람
├── scripts/
│   └── deploy.sh              # 배포 헬퍼 스크립트
└── README.md
```

## 모듈 설명

| 모듈 | 설명 | 주요 리소스 |
|------|------|------------|
| `vpc` | 네트워크 인프라 | VPC, Public/Private 서브넷, NAT Gateway, 보안 그룹 |
| `ecs` | 컨테이너 오케스트레이션 | ECS Fargate 클러스터, web-client/scanner-api 서비스 |
| `alb` | 로드 밸런서 | ALB, HTTPS 리스너, 타겟 그룹, ACM 인증서 |
| `ec2_agent` | 익스플로잇 에이전트 | EC2 인스턴스 (Docker-in-Docker), IAM 역할 |
| `ecr` | 컨테이너 레지스트리 | ECR 저장소 (web-client, scanner-api, exploit-agent, exploit-sandbox) |
| `secrets` | 시크릿 관리 | AWS Secrets Manager 시크릿 |
| `monitoring` | 모니터링 | CloudWatch 로그 그룹, 알람, SNS 토픽 |

## 보안 그룹

| 보안 그룹 | 인바운드 | 아웃바운드 |
|-----------|----------|-----------|
| `alb-sg` | 80, 443 from 0.0.0.0/0 | ECS 보안 그룹으로 모든 트래픽 |
| `ecs-sg` | 3000, 8080 from ALB | 443 (OpenAI, Supabase) |
| `agent-sg` | 8081 from ECS | 443 (OpenAI) |

## 비용 추정

### 개발 환경 (월간 예상 비용)

| 리소스 | 비용 | 비고 |
|--------|------|------|
| ALB | ~$20 | 시간당 + LCU |
| NAT Gateway | ~$35 | 시간당 + 데이터 처리 |
| ECS Fargate (2 서비스) | ~$45 | Spot 사용 시 ~70% 절감 |
| EC2 t3.medium | ~$30 | 온디맨드 기준 |
| ECR | ~$5 | 스토리지 기준 |
| Secrets Manager | ~$3 | 시크릿 수 기준 |
| CloudWatch | ~$5 | 로그 및 알람 |
| **총계** | **~$150** | |

### 비용 절감 팁

1. **Fargate Spot 사용**: `use_fargate_spot = true` 설정으로 ~70% 절감
2. **NAT Gateway 공유**: 단일 NAT Gateway로 모든 AZ 커버
3. **EC2 Spot/Reserved**: 익스플로잇 에이전트용 EC2를 Spot 또는 Reserved 인스턴스로 변경

## 문제 해결

### 일반적인 오류

#### Terraform init 실패
```bash
# 캐시 삭제 후 재시도
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### ACM 인증서 검증 대기
```bash
# 인증서 상태 확인
aws acm describe-certificate --certificate-arn <arn>

# DNS 검증 레코드를 수동으로 추가해야 할 수 있음
```

#### ECS 서비스 시작 실패
```bash
# 태스크 중지 사유 확인
aws ecs describe-tasks \
  --cluster killhouse-cluster \
  --tasks <task-arn>

# CloudWatch 로그 확인
aws logs get-log-events \
  --log-group-name /ecs/killhouse/scanner-api \
  --log-stream-name <stream-name>
```

#### ECR 이미지 푸시 실패
```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-2.amazonaws.com
```

### 유용한 명령어

```bash
# VPC 정보 확인
terraform output vpc_id

# ALB DNS 이름 확인
terraform output alb_dns_name

# NAT Gateway IP 확인 (외부 서비스 allowlist 등록용)
terraform output nat_gateway_ip

# 모든 출력 값 확인
terraform output -json
```

## 관련 저장소

- [killhouse-web-client](https://github.com/your-org/killhouse-web-client) - 프론트엔드
- [killhouse-vuln-scanner-engine](https://github.com/your-org/killhouse-vuln-scanner-engine) - 스캐너 엔진

## License

Private - All rights reserved
