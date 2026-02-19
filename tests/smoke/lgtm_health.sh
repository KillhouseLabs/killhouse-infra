#!/bin/bash
# Post-deploy smoke test: LGTM stack health verification
# Run from a machine with kubectl access to the cluster
#
# Usage:
#   ./tests/smoke/lgtm_health.sh
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS=0
FAIL=0
NS="killhouse-monitoring"

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
echo " LGTM Stack Smoke Tests"
echo "======================================"
echo ""

echo "--- Namespace ---"
check "namespace exists" \
  "kubectl get ns $NS -o jsonpath='{.metadata.name}'" \
  "$NS"

echo ""
echo "--- Mimir (Metrics) ---"
check "mimir pod running" \
  "kubectl get pods -n $NS -l app.kubernetes.io/name=mimir --no-headers | grep -c Running" \
  "1"
check "mimir ready" \
  "kubectl exec -n $NS statefulset/mimir -- wget -qO- http://localhost:8080/ready" \
  "ready"

echo ""
echo "--- Loki (Logs) ---"
check "loki pod running" \
  "kubectl get pods -n $NS -l app.kubernetes.io/name=loki --no-headers | grep -c Running" \
  "1"
check "loki ready" \
  "kubectl exec -n $NS statefulset/loki -- wget -qO- http://localhost:3100/ready" \
  "ready"

echo ""
echo "--- Tempo (Traces) ---"
check "tempo pod running" \
  "kubectl get pods -n $NS -l app.kubernetes.io/name=tempo --no-headers | grep -c Running" \
  "1"
check "tempo ready" \
  "kubectl exec -n $NS statefulset/tempo -- wget -qO- http://localhost:3200/ready" \
  "ready"

echo ""
echo "--- Grafana ---"
check "grafana pod running" \
  "kubectl get pods -n $NS -l app.kubernetes.io/name=grafana --no-headers | grep -c Running" \
  "1"
check "grafana healthy" \
  "kubectl exec -n $NS deployment/grafana -- wget -qO- http://localhost:3000/api/health | tr -d '[:space:]'" \
  "ok"
check "grafana datasources configured" \
  "kubectl exec -n $NS deployment/grafana -- wget -qO- http://localhost:3000/api/datasources 2>/dev/null | grep -c uid" \
  "3"

echo ""
echo "--- Alloy (Collector) ---"
check "alloy pods running" \
  "kubectl get pods -n $NS -l app.kubernetes.io/name=alloy --no-headers | grep -c Running" \
  "3"
check "alloy ready" \
  "kubectl exec -n $NS daemonset/alloy -- wget -qO- http://localhost:12345/-/ready" \
  "ready"

echo ""
echo "--- Integration ---"
check "mimir receiving metrics" \
  "kubectl exec -n $NS statefulset/mimir -- wget -qO- 'http://localhost:8080/prometheus/api/v1/label/__name__/values' | grep -c up" \
  "1"

echo ""
echo "======================================"
echo -e " Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "======================================"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
