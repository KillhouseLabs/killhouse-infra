# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------
project     = "killhouse"
environment = "dev"
region      = "ap-northeast-2"

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
enable_nat_gateway = true
admin_cidr         = ""

# VPC Security
enable_flow_logs     = true
enable_vpc_endpoints = false

# -----------------------------------------------------------------------------
# Domain & TLS (Caddy + Let's Encrypt)
# -----------------------------------------------------------------------------
domain_name = "killhouselabs.duckdns.org"
acme_email  = "lonelynight1026@gmail.com"

# -----------------------------------------------------------------------------
# EC2 - App
# -----------------------------------------------------------------------------
app_instance_type = "t3.large"

# -----------------------------------------------------------------------------
# GitHub OIDC
# -----------------------------------------------------------------------------
github_org = "KillhouseLabs"

# -----------------------------------------------------------------------------
# Monitoring (CloudWatch)
# -----------------------------------------------------------------------------
create_alarm_sns_topic = false
alarm_email            = ""

# -----------------------------------------------------------------------------
# LGTM Monitoring Stack
# -----------------------------------------------------------------------------
monitor_domain_name = "killhouselabs-monitor.duckdns.org"
smtp_user           = "lonelynight1026@gmail.com"
# grafana_admin_password → GitHub Secret: GRAFANA_ADMIN_PASSWORD
# smtp_password          → GitHub Secret: SMTP_PASSWORD
