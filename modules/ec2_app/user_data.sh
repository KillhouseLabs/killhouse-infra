#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting Killhouse App Setup ==="

# Update system
dnf update -y

# Install Docker
dnf install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Docker Compose v2 plugin
mkdir -p /usr/local/lib/docker/cli-plugins
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -SL "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install AWS CLI and jq (if not present)
if ! command -v aws &> /dev/null; then
    dnf install -y aws-cli
fi
dnf install -y jq

# ECR Login
echo "=== Logging into ECR ==="
aws ecr get-login-password --region ${region} | \
    docker login --username AWS --password-stdin ${ecr_registry_url}

# Create app directory
mkdir -p /opt/killhouse

# Fetch secrets from AWS Secrets Manager
echo "=== Fetching secrets ==="
get_secret() {
    local arn="$1"
    aws secretsmanager get-secret-value --secret-id "$arn" --query SecretString --output text --region ${region} 2>/dev/null || echo ""
}

DATABASE_URL=$(get_secret "${database_url_secret_arn}")
DIRECT_URL=$(get_secret "${direct_url_secret_arn}")
AUTH_SECRET=$(get_secret "${auth_secret_arn}")
AUTH_URL=$(get_secret "${auth_url_secret_arn}")
GITHUB_CLIENT_ID=$(get_secret "${github_client_id_secret_arn}")
GITHUB_CLIENT_SECRET=$(get_secret "${github_client_secret_arn}")
NEXT_PUBLIC_IMP_CODE=$(get_secret "${portone_imp_code_secret_arn}")
OPENAI_API_KEY=$(get_secret "${openai_api_key_secret_arn}")
SUPABASE_URL=$(get_secret "${supabase_url_secret_arn}")
SUPABASE_KEY=$(get_secret "${supabase_key_secret_arn}")

# Write .env file
cat > /opt/killhouse/.env << EOF
DATABASE_URL=$${DATABASE_URL}
DIRECT_URL=$${DIRECT_URL}
AUTH_SECRET=$${AUTH_SECRET}
AUTH_URL=$${AUTH_URL}
GITHUB_CLIENT_ID=$${GITHUB_CLIENT_ID}
GITHUB_CLIENT_SECRET=$${GITHUB_CLIENT_SECRET}
NEXT_PUBLIC_IMP_CODE=$${NEXT_PUBLIC_IMP_CODE}
OPENAI_API_KEY=$${OPENAI_API_KEY}
SUPABASE_URL=$${SUPABASE_URL}
SUPABASE_KEY=$${SUPABASE_KEY}
EOF

chmod 600 /opt/killhouse/.env

# Write Caddyfile
cat > /opt/killhouse/Caddyfile << 'CADDYEOF'
${caddyfile_content}
CADDYEOF

# Write docker-compose.yml
cat > /opt/killhouse/docker-compose.yml << 'COMPOSEEOF'
${compose_content}
COMPOSEEOF

# Pull images and start services
echo "=== Starting Docker Compose services ==="
cd /opt/killhouse
docker compose pull || echo "Some images not available yet, will retry"
docker compose up -d || echo "Docker Compose start deferred"

# Create systemd service for killhouse
cat > /etc/systemd/system/killhouse.service << 'SERVICEEOF'
[Unit]
Description=Killhouse Docker Compose Services
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/killhouse
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose pull && /usr/bin/docker compose up -d

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable killhouse.service

# Setup log rotation
cat > /etc/logrotate.d/killhouse << 'LOGEOF'
/var/log/killhouse/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
LOGEOF

echo "=== Killhouse App Setup Complete ==="
