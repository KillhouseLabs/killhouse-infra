# -----------------------------------------------------------------------------
# EC2 Instance for All Services (Caddy + Docker Compose)
# -----------------------------------------------------------------------------

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.app_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region           = var.region
    ecr_registry_url = var.ecr_registry_url
    environment      = var.environment
    # Secret ARNs - Database
    database_url_secret_arn = var.database_url_secret_arn
    direct_url_secret_arn   = var.direct_url_secret_arn
    # Secret ARNs - Auth
    auth_secret_arn     = var.auth_secret_arn
    auth_url_secret_arn = var.auth_url_secret_arn
    # Secret ARNs - OAuth
    github_client_id_secret_arn     = var.github_client_id_secret_arn
    github_client_secret_arn        = var.github_client_secret_secret_arn
    google_client_id_secret_arn     = var.google_client_id_secret_arn
    google_client_secret_secret_arn = var.google_client_secret_secret_arn
    gitlab_client_id_secret_arn     = var.gitlab_client_id_secret_arn
    gitlab_client_secret_secret_arn = var.gitlab_client_secret_secret_arn
    # Secret ARNs - Payment
    portone_imp_code_secret_arn    = var.portone_imp_code_secret_arn
    portone_channel_key_secret_arn = var.portone_channel_key_secret_arn
    portone_api_key_secret_arn     = var.portone_api_key_secret_arn
    portone_api_secret_secret_arn  = var.portone_api_secret_secret_arn
    # Secret ARNs - External services
    openai_api_key_secret_arn  = var.openai_api_key_secret_arn
    supabase_url_secret_arn    = var.supabase_url_secret_arn
    supabase_key_secret_arn    = var.supabase_key_secret_arn
    scanner_api_key_secret_arn = var.scanner_api_key_secret_arn
    # Config files (rendered from templates)
    caddyfile_content = local.caddyfile_content
    compose_content   = local.compose_content
    # LGTM monitoring config files
    loki_config           = local.loki_config
    mimir_config          = local.mimir_config
    alloy_config          = local.alloy_config
    grafana_datasources   = local.grafana_datasources
    grafana_contactpoints = local.grafana_contactpoints
    grafana_policies      = local.grafana_policies
    grafana_rules         = local.grafana_rules
  }))

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2
  }

  tags = {
    Name        = "${var.project}-app"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# -----------------------------------------------------------------------------
# Elastic IP
# -----------------------------------------------------------------------------

resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name        = "${var.project}-app-eip"
    Environment = var.environment
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}

# -----------------------------------------------------------------------------
# IAM Role for EC2
# -----------------------------------------------------------------------------

resource "aws_iam_role" "app" {
  name = "${var.project}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project}-app-profile"
  role = aws_iam_role.app.name
}

# ECR pull permission
resource "aws_iam_role_policy" "app_ecr" {
  name = "${var.project}-app-ecr-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Secrets Manager access
resource "aws_iam_role_policy" "app_secrets" {
  name = "${var.project}-app-secrets-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secret_arns
      }
    ]
  })
}

# CloudWatch Logs
resource "aws_iam_role_policy" "app_logs" {
  name = "${var.project}-app-logs-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# SSM for remote management
resource "aws_iam_role_policy_attachment" "app_ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------
# Config Sync (Caddyfile + docker-compose.yml)
# -----------------------------------------------------------------------------
# When domain_name, acme_email, or compose template changes,
# automatically push updated configs to EC2 via SSM.

locals {
  caddyfile_content = templatefile("${path.module}/Caddyfile.tpl", {
    domain_name         = var.domain_name
    monitor_domain_name = var.monitor_domain_name
    acme_email          = var.acme_email
  })
  compose_content = templatefile("${path.module}/docker-compose.yml.tpl", {
    ecr_registry_url       = var.ecr_registry_url
    environment            = var.environment
    domain_name            = var.domain_name
    monitor_domain_name    = var.monitor_domain_name
    grafana_admin_password = var.grafana_admin_password
    smtp_user              = var.smtp_user
    smtp_password          = var.smtp_password
  })

  # LGTM config files (static, no template variables needed)
  loki_config  = file("${path.module}/lgtm/loki-config.yaml")
  mimir_config = file("${path.module}/lgtm/mimir-config.yaml")
  alloy_config = file("${path.module}/lgtm/alloy-config.alloy")

  # Grafana provisioning files
  grafana_datasources  = file("${path.module}/lgtm/grafana/provisioning/datasources/datasources.yaml")
  grafana_contactpoints = file("${path.module}/lgtm/grafana/provisioning/alerting/contactpoints.yaml")
  grafana_policies     = file("${path.module}/lgtm/grafana/provisioning/alerting/policies.yaml")
  grafana_rules        = file("${path.module}/lgtm/grafana/provisioning/alerting/rules.yaml")
}

resource "local_file" "ssm_config_sync" {
  filename = "${path.module}/.ssm-config-sync.json"
  content = jsonencode({
    commands = concat(
      # Caddyfile
      ["cat > /opt/killhouse/Caddyfile << '____CADDYEOF'"],
      split("\n", local.caddyfile_content),
      ["____CADDYEOF"],
      # docker-compose.yml
      ["cat > /opt/killhouse/docker-compose.yml << '____COMPOSEEOF'"],
      split("\n", local.compose_content),
      ["____COMPOSEEOF"],
      # LGTM config directory structure
      ["mkdir -p /opt/killhouse/lgtm/grafana/provisioning/{datasources,alerting}"],
      # Loki config
      ["cat > /opt/killhouse/lgtm/loki-config.yaml << '____LOKIEOF'"],
      split("\n", local.loki_config),
      ["____LOKIEOF"],
      # Mimir config
      ["cat > /opt/killhouse/lgtm/mimir-config.yaml << '____MIMIREOF'"],
      split("\n", local.mimir_config),
      ["____MIMIREOF"],
      # Alloy config
      ["cat > /opt/killhouse/lgtm/alloy-config.alloy << '____ALLOYEOF'"],
      split("\n", local.alloy_config),
      ["____ALLOYEOF"],
      # Grafana datasources
      ["cat > /opt/killhouse/lgtm/grafana/provisioning/datasources/datasources.yaml << '____DSEOF'"],
      split("\n", local.grafana_datasources),
      ["____DSEOF"],
      # Grafana alerting - contact points
      ["cat > /opt/killhouse/lgtm/grafana/provisioning/alerting/contactpoints.yaml << '____CPEOF'"],
      split("\n", local.grafana_contactpoints),
      ["____CPEOF"],
      # Grafana alerting - policies
      ["cat > /opt/killhouse/lgtm/grafana/provisioning/alerting/policies.yaml << '____POLEOF'"],
      split("\n", local.grafana_policies),
      ["____POLEOF"],
      # Grafana alerting - rules
      ["cat > /opt/killhouse/lgtm/grafana/provisioning/alerting/rules.yaml << '____RULEEOF'"],
      split("\n", local.grafana_rules),
      ["____RULEEOF"],
      # Reload Caddy and restart monitoring stack
      ["cd /opt/killhouse && docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || echo 'Caddy not running, skip reload'"]
    )
  })
}

resource "terraform_data" "config_sync" {
  triggers_replace = {
    caddyfile     = sha256(local.caddyfile_content)
    compose       = sha256(local.compose_content)
    loki_config   = sha256(local.loki_config)
    mimir_config  = sha256(local.mimir_config)
    alloy_config  = sha256(local.alloy_config)
    grafana_ds    = sha256(local.grafana_datasources)
    grafana_cp    = sha256(local.grafana_contactpoints)
    grafana_pol   = sha256(local.grafana_policies)
    grafana_rules = sha256(local.grafana_rules)
  }

  provisioner "local-exec" {
    command = "aws ssm send-command --region ${var.region} --instance-ids ${aws_instance.app.id} --document-name AWS-RunShellScript --parameters file://${local_file.ssm_config_sync.filename} --query Command.CommandId --output text"
  }

  depends_on = [aws_instance.app, local_file.ssm_config_sync]
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ec2/${var.project}/app"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}
