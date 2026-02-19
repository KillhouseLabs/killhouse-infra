#!/bin/bash
set -euo pipefail

# Logging
exec > >(tee /var/log/k3s-setup.log) 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting k3s node setup..."

# -----------------------------------------------------------------------------
# System packages
# -----------------------------------------------------------------------------
dnf update -y
dnf install -y curl tar gzip jq amazon-ssm-agent
systemctl enable --now amazon-ssm-agent

# -----------------------------------------------------------------------------
# Install gVisor (runsc)
# -----------------------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing gVisor..."

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  URL=https://storage.googleapis.com/gvisor/releases/release/latest/x86_64
elif [ "$ARCH" = "aarch64" ]; then
  URL=https://storage.googleapis.com/gvisor/releases/release/latest/aarch64
fi

curl -fsSL "$URL/runsc" -o /usr/local/bin/runsc
curl -fsSL "$URL/containerd-shim-runsc-v1" -o /usr/local/bin/containerd-shim-runsc-v1
chmod +x /usr/local/bin/runsc /usr/local/bin/containerd-shim-runsc-v1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] gVisor installed: $(runsc --version)"

# -----------------------------------------------------------------------------
# k3s containerd config (with gVisor runtime)
# -----------------------------------------------------------------------------
mkdir -p /etc/rancher/k3s
cat > /etc/rancher/k3s/config.yaml <<CONFIGEOF
write-kubeconfig-mode: "0644"
tls-san:
  - "${node_name}"
kubelet-arg:
  - "max-pods=110"
CONFIGEOF

# Containerd config template with gVisor runtime
mkdir -p /var/lib/rancher/k3s/agent/etc/containerd
cat > /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl <<'CONTAINERDEOF'
version = 2

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc.options]
  TypeUrl = "io.containerd.runsc.v1.options"
CONTAINERDEOF

# -----------------------------------------------------------------------------
# Install k3s
# -----------------------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing k3s ${k3s_version}..."

export INSTALL_K3S_VERSION="${k3s_version}"
export K3S_TOKEN="${k3s_token}"

%{ if is_init_node ~}
# Init node: bootstrap embedded etcd cluster
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-init \
  --node-name "${node_name}" \
  --disable servicelb \
  --disable traefik
%{ else ~}
# Join node: connect to init node
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for init node at ${init_node_ip}:6443..."

for i in $(seq 1 60); do
  if curl -sk "https://${init_node_ip}:6443/ping" 2>/dev/null | grep -q ok; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Init node is ready."
    break
  fi
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting... ($i/60)"
  sleep 10
done

curl -sfL https://get.k3s.io | sh -s - server \
  --server "https://${init_node_ip}:6443" \
  --node-name "${node_name}" \
  --disable servicelb \
  --disable traefik
%{ endif ~}

# -----------------------------------------------------------------------------
# Wait for k3s to be ready
# -----------------------------------------------------------------------------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for k3s to be ready..."
for i in $(seq 1 30); do
  if /usr/local/bin/kubectl get nodes &>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] k3s is ready."
    break
  fi
  sleep 5
done

# -----------------------------------------------------------------------------
# Create RuntimeClass and node labels
# -----------------------------------------------------------------------------
%{ if is_init_node ~}
# Create gVisor RuntimeClass (only on init node)
/usr/local/bin/kubectl apply -f - <<'RUNTIMEEOF'
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
RUNTIMEEOF

# Create sandbox namespace label
/usr/local/bin/kubectl label node "${node_name}" killhouse.io/role=server --overwrite

echo "[$(date '+%Y-%m-%d %H:%M:%S')] RuntimeClass 'gvisor' created."
%{ else ~}
/usr/local/bin/kubectl label node "${node_name}" killhouse.io/role=server --overwrite 2>/dev/null || true
%{ endif ~}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] k3s node setup complete."
