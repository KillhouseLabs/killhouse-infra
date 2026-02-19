#!/bin/bash
# Post-deploy smoke test: core services health verification
# Run from a machine with kubectl access to the cluster
#
# Usage:
#   ./tests/smoke/core_services_health.sh
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS=0
FAIL=0
NS="killhouse-system"

check() {
  local name="$1"
  local cmd="$2"
  local expect="$3"

  echo -n "  [$name] "
  RESULT=$(eval "$cmd" 2>/dev/null || echo "ERROR")

  if [[ "$RESULT" == *"$expect"* ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
  else
    echo -e "${RED}FAIL${NC} (expected: '$expect', got: '$RESULT')"
    ((FAIL++))
  fi
}

echo "======================================"
echo " Core Services Smoke Tests"
echo "======================================"
echo ""

echo "--- Namespace ---"
check "namespace exists" \
  "kubectl get ns $NS -o jsonpath='{.metadata.name}'" \
  "$NS"

echo ""
echo "--- web-client ---"
check "web-client running" \
  "kubectl get deploy web-client -n $NS -o jsonpath='{.status.readyReplicas}'" \
  "1"
check "web-client endpoint" \
  "kubectl exec -n $NS deploy/web-client -- wget -qO- --timeout=5 http://localhost:3000/ 2>&1 | head -1" \
  "<!DOCTYPE"

echo ""
echo "--- scanner-api ---"
check "scanner-api running" \
  "kubectl get deploy scanner-api -n $NS -o jsonpath='{.status.readyReplicas}'" \
  "1"
check "scanner-api health" \
  "kubectl exec -n $NS deploy/scanner-api -- wget -qO- --timeout=5 http://localhost:8080/health 2>/dev/null" \
  "ok"

echo ""
echo "--- exploit-agent ---"
check "exploit-agent running" \
  "kubectl get deploy exploit-agent -n $NS -o jsonpath='{.status.readyReplicas}'" \
  "1"
check "exploit-agent health" \
  "kubectl exec -n $NS deploy/exploit-agent -- wget -qO- --timeout=5 http://localhost:8001/health 2>/dev/null" \
  "ok"

echo ""
echo "--- sandbox-controller ---"
check "sandbox-controller running" \
  "kubectl get deploy sandbox-controller -n $NS -o jsonpath='{.status.readyReplicas}'" \
  "1"
check "sandbox-controller health" \
  "kubectl exec -n $NS deploy/sandbox-controller -- wget -qO- --timeout=5 http://localhost:8000/health 2>/dev/null" \
  "ok"

echo ""
echo "--- RBAC ---"
check "sandbox-controller SA exists" \
  "kubectl get sa sandbox-controller -n $NS -o jsonpath='{.metadata.name}'" \
  "sandbox-controller"
check "scanner-api SA exists" \
  "kubectl get sa scanner-api -n $NS -o jsonpath='{.metadata.name}'" \
  "scanner-api"

echo ""
echo "--- Networking ---"
check "ingress configured" \
  "kubectl get ingress killhouse -n $NS -o jsonpath='{.spec.rules[0].host}'" \
  "staging.killhouselabs.duckdns.org"

echo ""
echo "--- Cross-service communication ---"
check "web-client -> scanner-api" \
  "kubectl exec -n $NS deploy/web-client -- wget -qO- --timeout=5 http://scanner-api:8080/health 2>/dev/null" \
  "ok"
check "exploit-agent -> sandbox-controller" \
  "kubectl exec -n $NS deploy/exploit-agent -- wget -qO- --timeout=5 http://sandbox-controller:8000/health 2>/dev/null" \
  "ok"

echo ""
echo "--- Security: no docker.sock ---"
check "no docker.sock volumes" \
  "kubectl get deploy -n $NS -o json | grep -c docker.sock || echo 0" \
  "0"

echo ""
echo "======================================"
echo -e " Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "======================================"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
