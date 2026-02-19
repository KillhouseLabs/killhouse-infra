#!/bin/bash
# Run terraform-compliance BDD tests against plan output
#
# Usage:
#   ./tests/run_compliance.sh [environment]
#
# Prerequisites:
#   pip install terraform-compliance
#
set -euo pipefail

ENVIRONMENT=${1:-staging}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$ROOT_DIR/environments/$ENVIRONMENT"
PLAN_FILE="$ENV_DIR/tfplan"
PLAN_JSON="$ENV_DIR/tfplan.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "======================================"
echo " Terraform Compliance Tests"
echo " Environment: $ENVIRONMENT"
echo "======================================"
echo ""

# Check prerequisites
if ! command -v terraform-compliance &>/dev/null; then
  echo -e "${RED}Error: terraform-compliance not installed${NC}"
  echo "Install with: pip install terraform-compliance"
  exit 1
fi

# Generate plan JSON if not exists or stale
if [ ! -f "$PLAN_JSON" ] || [ "$PLAN_FILE" -nt "$PLAN_JSON" ] 2>/dev/null; then
  echo "Generating plan JSON..."
  cd "$ENV_DIR"

  if [ ! -f "$PLAN_FILE" ]; then
    echo "No plan file found. Running terraform plan..."
    terraform plan -out=tfplan -var="k3s_token=test-token-for-compliance" 2>/dev/null
  fi

  terraform show -json tfplan > tfplan.json
  echo "Plan JSON generated."
  echo ""
fi

# Run compliance tests
echo "Running BDD tests..."
echo ""

terraform-compliance \
  -p "$PLAN_JSON" \
  -f "$SCRIPT_DIR/compliance/"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}All compliance tests passed.${NC}"
else
  echo -e "${RED}Some compliance tests failed.${NC}"
fi

# Cleanup plan JSON (contains sensitive data)
rm -f "$PLAN_JSON"

exit $EXIT_CODE
