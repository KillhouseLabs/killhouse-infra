#!/bin/bash
# Post-deploy smoke test: sandbox lifecycle + gVisor + BuildKit
# Run from a machine with kubectl access to the cluster
#
# Usage:
#   ./tests/smoke/sandbox_lifecycle.sh
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS=0
FAIL=0
TEST_SANDBOX="sandbox-smoke-test"
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

cleanup() {
  echo ""
  echo "--- Cleanup ---"
  kubectl delete namespace "$TEST_SANDBOX" --ignore-not-found --wait=false 2>/dev/null
  echo "  Sandbox namespace deletion initiated."
}
trap cleanup EXIT

echo "======================================"
echo " Sandbox Lifecycle Smoke Tests"
echo "======================================"
echo ""

echo "--- BuildKit ---"
check "buildkitd running" \
  "kubectl get sts buildkitd -n $NS -o jsonpath='{.status.readyReplicas}'" \
  "1"
check "buildkitd workers available" \
  "kubectl exec -n $NS sts/buildkitd -- buildctl debug workers 2>&1 | grep -c running" \
  "1"

echo ""
echo "--- Sandbox Namespace Creation ---"
kubectl create namespace "$TEST_SANDBOX" 2>/dev/null || true
kubectl label namespace "$TEST_SANDBOX" killhouse.io/sandbox=true --overwrite 2>/dev/null

check "namespace created" \
  "kubectl get ns $TEST_SANDBOX -o jsonpath='{.metadata.name}'" \
  "$TEST_SANDBOX"

echo ""
echo "--- NetworkPolicy ---"
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sandbox-isolation
  namespace: $TEST_SANDBOX
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: killhouse-system
  egress:
  - to:
    - podSelector: {}
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF

check "network policy applied" \
  "kubectl get networkpolicy sandbox-isolation -n $TEST_SANDBOX -o jsonpath='{.metadata.name}'" \
  "sandbox-isolation"

echo ""
echo "--- ResourceQuota ---"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: sandbox-quota
  namespace: $TEST_SANDBOX
spec:
  hard:
    limits.cpu: "4"
    limits.memory: 4Gi
    pods: "5"
EOF

check "resource quota applied" \
  "kubectl get resourcequota sandbox-quota -n $TEST_SANDBOX -o jsonpath='{.spec.hard.pods}'" \
  "5"

echo ""
echo "--- gVisor Target Pod ---"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: target-test
  namespace: $TEST_SANDBOX
  labels:
    killhouse.io/component: target
spec:
  runtimeClassName: gvisor
  automountServiceAccountToken: false
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
  containers:
  - name: app
    image: busybox:1.37
    command: ["sh", "-c", "echo sandbox-ok && sleep 30"]
    resources:
      requests: { cpu: 50m, memory: 32Mi }
      limits: { cpu: 100m, memory: 64Mi }
  restartPolicy: Never
EOF

echo "  Waiting for pod to start..."
kubectl wait --for=condition=Ready pod/target-test -n "$TEST_SANDBOX" --timeout=60s 2>/dev/null || true

check "gVisor pod running" \
  "kubectl get pod target-test -n $TEST_SANDBOX -o jsonpath='{.status.phase}'" \
  "Running"

check "gVisor runtime confirmed" \
  "kubectl get pod target-test -n $TEST_SANDBOX -o jsonpath='{.spec.runtimeClassName}'" \
  "gvisor"

check "pod output correct" \
  "kubectl logs target-test -n $TEST_SANDBOX" \
  "sandbox-ok"

echo ""
echo "--- Namespace Cascade Delete ---"
kubectl delete namespace "$TEST_SANDBOX" --wait=true --timeout=30s 2>/dev/null || true

check "namespace deleted" \
  "kubectl get ns $TEST_SANDBOX 2>&1" \
  "not found"

# Disable trap since we already cleaned up
trap - EXIT

echo ""
echo "======================================"
echo -e " Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "======================================"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
