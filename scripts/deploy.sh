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
if [ ! -f "terraform.tfvars" ]; then
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
    *)
        echo "Usage: $0 <environment> <action>"
        echo ""
        echo "Environments: dev, prod"
        echo "Actions: init, plan, apply, destroy, output"
        echo ""
        echo "Examples:"
        echo "  $0 dev init     # Initialize Terraform for dev"
        echo "  $0 dev plan     # Plan changes for dev"
        echo "  $0 dev apply    # Apply changes to dev"
        echo "  $0 prod plan    # Plan changes for prod"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
