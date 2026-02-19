#!/bin/bash
# Run K8s manifest validation tests
#
# Usage:
#   ./tests/run_k8s_tests.sh [manifests-dir]
#
# Prerequisites:
#   brew install conftest kubeconform (macOS)
#
set -euo pipefail

MANIFESTS_DIR=${1:-k8s}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
POLICY_DIR="$SCRIPT_DIR/policy"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================"
echo " K8s Manifest Tests"
echo " Manifests: $MANIFESTS_DIR"
echo "======================================"
echo ""

OVERALL_EXIT=0

# 1. Schema validation with kubeconform
if command -v kubeconform &>/dev/null; then
  echo "--- Schema Validation (kubeconform) ---"
  find "$ROOT_DIR/$MANIFESTS_DIR" -name '*.yaml' -o -name '*.yml' | while read -r f; do
    echo -n "  $(basename "$f"): "
    if kubeconform -strict -summary "$f" 2>&1 | grep -q "Summary.*0 invalid"; then
      echo -e "${GREEN}VALID${NC}"
    else
      echo -e "${RED}INVALID${NC}"
      kubeconform -strict "$f" 2>&1
      OVERALL_EXIT=1
    fi
  done
  echo ""
else
  echo -e "${YELLOW}kubeconform not found, skipping schema validation${NC}"
  echo "Install with: brew install kubeconform"
  echo ""
fi

# 2. Policy tests with conftest
if command -v conftest &>/dev/null; then
  echo "--- Policy Tests (conftest/OPA) ---"
  conftest test "$ROOT_DIR/$MANIFESTS_DIR/" \
    --policy "$POLICY_DIR" \
    --all-namespaces 2>&1
  if [ $? -ne 0 ]; then
    OVERALL_EXIT=1
  fi
  echo ""
else
  echo -e "${YELLOW}conftest not found, skipping policy tests${NC}"
  echo "Install with: brew install conftest"
  echo ""
fi

echo "======================================"
if [ $OVERALL_EXIT -eq 0 ]; then
  echo -e "${GREEN}All K8s manifest tests passed.${NC}"
else
  echo -e "${RED}Some K8s manifest tests failed.${NC}"
fi
echo "======================================"

exit $OVERALL_EXIT
