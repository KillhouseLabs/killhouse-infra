#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$ROOT_DIR/environments/$ENVIRONMENT"

echo -e "${GREEN}=== Killhouse Infrastructure Deployment ===${NC}"
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo ""

# Check if environment directory exists
if [ ! -d "$ENV_DIR" ]; then
    echo -e "${RED}Error: Environment '$ENVIRONMENT' not found${NC}"
    echo "Available environments:"
    ls -1 "$ROOT_DIR/environments/"
    exit 1
fi

cd "$ENV_DIR"

# Check for terraform.tfvars
if [ "$ACTION" != "ec2-deploy" ] && [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}Warning: terraform.tfvars not found${NC}"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it."
    exit 1
fi

case $ACTION in
    init)
        echo -e "${GREEN}Initializing Terraform...${NC}"
        terraform init -upgrade
        ;;
    plan)
        echo -e "${GREEN}Planning infrastructure changes...${NC}"
        terraform plan -out=tfplan
        ;;
    apply)
        echo -e "${GREEN}Applying infrastructure changes...${NC}"
        if [ -f "tfplan" ]; then
            terraform apply tfplan
            rm -f tfplan
        else
            terraform apply
        fi
        ;;
    destroy)
        echo -e "${RED}WARNING: This will destroy all infrastructure!${NC}"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy
        else
            echo "Cancelled."
        fi
        ;;
    output)
        echo -e "${GREEN}Terraform outputs:${NC}"
        terraform output
        ;;
    ec2-deploy)
        echo -e "${GREEN}Deploying to EC2 via SSM...${NC}"

        # Get instance ID from Terraform output or AWS
        INSTANCE_ID=$(terraform output -raw app_instance_id 2>/dev/null || \
            aws ec2 describe-instances \
                --filters "Name=tag:Name,Values=killhouse-app" "Name=instance-state-name,Values=running" \
                --query 'Reservations[0].Instances[0].InstanceId' \
                --output text)

        if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
            echo -e "${RED}Error: Could not find app instance ID${NC}"
            exit 1
        fi

        echo "Instance ID: $INSTANCE_ID"

        REGION=$(terraform output -raw region 2>/dev/null || echo "ap-northeast-2")

        COMMAND_ID=$(aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters "commands=[\"cd /opt/killhouse && aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin \$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com && docker compose pull && docker compose up -d\"]" \
            --query 'Command.CommandId' \
            --output text)

        echo "SSM Command ID: $COMMAND_ID"
        echo "Waiting for deployment to complete..."

        aws ssm wait command-executed \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" || true

        STATUS=$(aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query 'Status' \
            --output text)

        if [ "$STATUS" = "Success" ]; then
            echo -e "${GREEN}Deployment successful!${NC}"
        else
            echo -e "${RED}Deployment status: $STATUS${NC}"
            aws ssm get-command-invocation \
                --command-id "$COMMAND_ID" \
                --instance-id "$INSTANCE_ID" \
                --query '[StandardOutputContent, StandardErrorContent]' \
                --output text
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 <environment> <action>"
        echo ""
        echo "Environments: dev, prod"
        echo "Actions: init, plan, apply, destroy, output, ec2-deploy"
        echo ""
        echo "Examples:"
        echo "  $0 dev init        # Initialize Terraform for dev"
        echo "  $0 dev plan        # Plan changes for dev"
        echo "  $0 dev apply       # Apply changes to dev"
        echo "  $0 dev ec2-deploy  # Deploy latest images to EC2"
        echo "  $0 prod plan       # Plan changes for prod"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
