#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting Killhouse App Setup ==="

# Update system
dnf update -y

# Install Docker
dnf install -y docker

# Enable Docker daemon metrics for Alloy to scrape
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'DOCKERCFG'
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true
}
DOCKERCFG

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

# Database
DATABASE_URL=$(get_secret "${database_url_secret_arn}")
DIRECT_URL=$(get_secret "${direct_url_secret_arn}")

# Auth
AUTH_SECRET=$(get_secret "${auth_secret_arn}")
AUTH_URL=$(get_secret "${auth_url_secret_arn}")

# OAuth - GitHub
GITHUB_CLIENT_ID=$(get_secret "${github_client_id_secret_arn}")
GITHUB_CLIENT_SECRET=$(get_secret "${github_client_secret_arn}")

# OAuth - Google
GOOGLE_CLIENT_ID=$(get_secret "${google_client_id_secret_arn}")
GOOGLE_CLIENT_SECRET=$(get_secret "${google_client_secret_secret_arn}")

# OAuth - GitLab
GITLAB_CLIENT_ID=$(get_secret "${gitlab_client_id_secret_arn}")
GITLAB_CLIENT_SECRET=$(get_secret "${gitlab_client_secret_secret_arn}")

# Payment - PortOne
NEXT_PUBLIC_IMP_CODE=$(get_secret "${portone_imp_code_secret_arn}")
NEXT_PUBLIC_PORTONE_CHANNEL_KEY=$(get_secret "${portone_channel_key_secret_arn}")
PORTONE_REST_API_KEY=$(get_secret "${portone_api_key_secret_arn}")
PORTONE_REST_API_SECRET=$(get_secret "${portone_api_secret_secret_arn}")

# External services
OPENAI_API_KEY=$(get_secret "${openai_api_key_secret_arn}")
SUPABASE_URL=$(get_secret "${supabase_url_secret_arn}")
SUPABASE_KEY=$(get_secret "${supabase_key_secret_arn}")
SCANNER_API_KEY=$(get_secret "${scanner_api_key_secret_arn}")

# Write .env file
cat > /opt/killhouse/.env << EOF
# Database
DATABASE_URL=$${DATABASE_URL}
DIRECT_URL=$${DIRECT_URL}

# Auth
AUTH_SECRET=$${AUTH_SECRET}
AUTH_URL=$${AUTH_URL}
NEXTAUTH_URL=$${AUTH_URL}
NEXTAUTH_SECRET=$${AUTH_SECRET}

# OAuth - GitHub
GITHUB_CLIENT_ID=$${GITHUB_CLIENT_ID}
GITHUB_CLIENT_SECRET=$${GITHUB_CLIENT_SECRET}

# OAuth - Google
GOOGLE_CLIENT_ID=$${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=$${GOOGLE_CLIENT_SECRET}

# OAuth - GitLab
GITLAB_CLIENT_ID=$${GITLAB_CLIENT_ID}
GITLAB_CLIENT_SECRET=$${GITLAB_CLIENT_SECRET}

# Payment - PortOne
NEXT_PUBLIC_IMP_CODE=$${NEXT_PUBLIC_IMP_CODE}
NEXT_PUBLIC_PORTONE_CHANNEL_KEY=$${NEXT_PUBLIC_PORTONE_CHANNEL_KEY}
PORTONE_REST_API_KEY=$${PORTONE_REST_API_KEY}
PORTONE_REST_API_SECRET=$${PORTONE_REST_API_SECRET}

# External services
OPENAI_API_KEY=$${OPENAI_API_KEY}
SUPABASE_URL=$${SUPABASE_URL}
SUPABASE_KEY=$${SUPABASE_KEY}

# Internal service URLs (Docker Compose network)
SCANNER_API_URL=http://scanner-api:8080
SCANNER_API_KEY=$${SCANNER_API_KEY}
SANDBOX_API_URL=http://sandbox:8000
ANALYSIS_API_URL=http://exploit-agent:8001
EOF

chmod 600 /opt/killhouse/.env

# Config files (Caddyfile, docker-compose.yml, LGTM configs) are pushed
# via SSM config sync after terraform apply. On first boot, the systemd
# service will start once configs arrive.
echo "=== Preparing directory structure ==="
mkdir -p /opt/killhouse/lgtm/grafana/provisioning/{datasources,alerting}

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

# === fail2ban installation and configuration ===
echo "=== Installing and configuring fail2ban ==="
dnf install -y fail2ban

# Configure fail2ban for SSH
cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 5
bantime = 600

[http-4xx]
enabled = true
port = http,https
filter = http-4xx
logpath = /var/log/caddy/access.log
maxretry = 30
findtime = 60
bantime = 1800
FAIL2BAN

# Create custom filter for HTTP 4xx abuse
cat > /etc/fail2ban/filter.d/http-4xx.conf << 'FILTER'
[Definition]
failregex = ^<HOST> .* "(GET|POST|PUT|DELETE|PATCH) .* HTTP/.*" (4[0-9]{2})
ignoreregex =
FILTER

systemctl enable fail2ban
systemctl start fail2ban

# === CloudWatch Agent for memory and disk metrics ===
echo "=== Installing CloudWatch Agent ==="
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWAGENT'
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 300
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 300,
        "resources": ["/"]
      }
    },
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    }
  }
}
CWAGENT

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "=== Killhouse App Setup Complete ==="
