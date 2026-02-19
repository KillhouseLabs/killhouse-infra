#!/bin/bash
# Post-apply smoke test: k3s cluster health verification
# Run via SSM on the init node after terraform apply
#
# Usage:
#   ./tests/smoke/k3s_cluster_health.sh <init-node-instance-id> [region]
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTANCE_ID=${1:?Usage: $0 <instance-id> [region]}
REGION=${2:-ap-northeast-2}
PASS=0
FAIL=0

run_remote() {
  local cmd="$1"
  aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"$cmd\"]" \
    --region "$REGION" \
    --output json 2>/dev/null | jq -r '.Command.CommandId'
}

get_output() {
  local cmd_id="$1"
  # Wait for command to complete
  for i in $(seq 1 30); do
    STATUS=$(aws ssm get-command-invocation \
      --command-id "$cmd_id" \
      --instance-id "$INSTANCE_ID" \
      --region "$REGION" \
      --query 'Status' --output text 2>/dev/null || echo "Pending")
    if [[ "$STATUS" == "Success" || "$STATUS" == "Failed" ]]; then
      break
    fi
    sleep 2
  done
  aws ssm get-command-invocation \
    --command-id "$cmd_id" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --output json 2>/dev/null
}

check() {
  local name="$1"
  local cmd="$2"
  local expect="$3"

  echo -n "  [$name] "
  CMD_ID=$(run_remote "$cmd")
  RESULT=$(get_output "$CMD_ID")
  STATUS=$(echo "$RESULT" | jq -r '.Status')
  STDOUT=$(echo "$RESULT" | jq -r '.StandardOutputContent' | tr -d '\n')

  if [[ "$STATUS" == "Success" && "$STDOUT" == *"$expect"* ]]; then
    echo -e "${GREEN}PASS${NC} ($STDOUT)"
    ((PASS++))
  else
    echo -e "${RED}FAIL${NC} (expected: '$expect', got: '$STDOUT', status: $STATUS)"
    ((FAIL++))
  fi
}

echo "======================================"
echo " k3s Cluster Smoke Tests"
echo " Instance: $INSTANCE_ID"
echo " Region:   $REGION"
echo "======================================"
echo ""

echo "--- Cluster Health ---"
check "k3s service running" \
  "systemctl is-active k3s" \
  "active"

check "kubectl accessible" \
  "kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' '" \
  "3"

check "all nodes Ready" \
  "kubectl get nodes --no-headers 2>/dev/null | grep -c Ready | tr -d ' '" \
  "3"

check "etcd members" \
  "ETCDCTL_API=3 etcdctl --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt --cert=/var/lib/rancher/k3s/server/tls/etcd/server-client.crt --key=/var/lib/rancher/k3s/server/tls/etcd/server-client.key member list 2>/dev/null | wc -l | tr -d ' '" \
  "3"

echo ""
echo "--- gVisor Runtime ---"
check "gVisor (runsc) installed" \
  "runsc --version 2>&1 | head -1" \
  "runsc version"

check "RuntimeClass gvisor exists" \
  "kubectl get runtimeclass gvisor -o jsonpath='{.handler}' 2>/dev/null" \
  "runsc"

check "gVisor test pod runs" \
  "kubectl run gvisor-test --image=busybox --restart=Never --runtime-class-name=gvisor --command -- echo gvisor-ok 2>/dev/null; sleep 5; kubectl logs gvisor-test 2>/dev/null; kubectl delete pod gvisor-test --ignore-not-found 2>/dev/null" \
  "gvisor-ok"

echo ""
echo "--- Networking ---"
check "CoreDNS running" \
  "kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep -c Running | tr -d ' '" \
  "1"

check "k3s API responding" \
  "curl -sk https://localhost:6443/healthz 2>/dev/null" \
  "ok"

echo ""
echo "======================================"
echo -e " Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "======================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
