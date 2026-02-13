#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting Exploit Agent Setup ==="

# Update system
dnf update -y

# Install Docker
dnf install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install AWS CLI v2 (if not present)
if ! command -v aws &> /dev/null; then
    dnf install -y aws-cli
fi

# Install jq for JSON parsing
dnf install -y jq

# ECR Login
echo "=== Logging into ECR ==="
aws ecr get-login-password --region ${region} | \
    docker login --username AWS --password-stdin ${ecr_registry_url}

# Create isolated network for sandbox containers
echo "=== Creating isolated network ==="
docker network create --driver bridge --internal killhouse-isolated || true

# Pull images
echo "=== Pulling Docker images ==="
docker pull ${ecr_registry_url}/${exploit_agent_image}:latest || echo "Agent image not found, will retry later"
docker pull ${ecr_registry_url}/${exploit_sandbox_image}:latest || echo "Sandbox image not found, will retry later"

# Get secrets from AWS Secrets Manager
echo "=== Fetching secrets ==="
OPENAI_API_KEY=$(aws secretsmanager get-secret-value --secret-id ${openai_secret_arn} --query SecretString --output text --region ${region} 2>/dev/null || echo "")
SUPABASE_URL=$(aws secretsmanager get-secret-value --secret-id ${supabase_url_secret_arn} --query SecretString --output text --region ${region} 2>/dev/null || echo "")
SUPABASE_KEY=$(aws secretsmanager get-secret-value --secret-id ${supabase_key_secret_arn} --query SecretString --output text --region ${region} 2>/dev/null || echo "")

# Create env file for agent
cat > /opt/exploit-agent/.env << EOF
OPENAI_API_KEY=$${OPENAI_API_KEY}
SUPABASE_URL=$${SUPABASE_URL}
SUPABASE_KEY=$${SUPABASE_KEY}
SANDBOX_IMAGE=${ecr_registry_url}/${exploit_sandbox_image}:latest
SANDBOX_NETWORK=killhouse-isolated
EOF

# Create systemd service for exploit-agent
cat > /etc/systemd/system/exploit-agent.service << 'EOF'
[Unit]
Description=Killhouse Exploit Agent
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/docker stop exploit-agent
ExecStartPre=-/usr/bin/docker rm exploit-agent
ExecStart=/usr/bin/docker run \
    --name exploit-agent \
    --env-file /opt/exploit-agent/.env \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p 8081:8081 \
    ${ecr_registry_url}/${exploit_agent_image}:latest
ExecStop=/usr/bin/docker stop exploit-agent

[Install]
WantedBy=multi-user.target
EOF

# Create directory for env file
mkdir -p /opt/exploit-agent

# Enable and start service (will fail if image not available yet)
systemctl daemon-reload
systemctl enable exploit-agent.service
systemctl start exploit-agent.service || echo "Service start deferred - image may not be available"

# Setup log rotation
cat > /etc/logrotate.d/exploit-agent << 'EOF'
/var/log/exploit-agent/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF

echo "=== Exploit Agent Setup Complete ==="
