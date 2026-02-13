# -----------------------------------------------------------------------------
# AWS Secrets Manager Secrets
# -----------------------------------------------------------------------------

# Note: Secret values should be set manually via AWS Console or CLI
# Do NOT commit actual secret values to version control

# -----------------------------------------------------------------------------
# Web Client Secrets
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "database_url" {
  name        = "${var.project}/${var.environment}/database-url"
  description = "Supabase PostgreSQL connection string (pooler)"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "direct_url" {
  name        = "${var.project}/${var.environment}/direct-url"
  description = "Supabase PostgreSQL direct connection string"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "auth_secret" {
  name        = "${var.project}/${var.environment}/auth-secret"
  description = "NextAuth.js secret key"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "auth_url" {
  name        = "${var.project}/${var.environment}/auth-url"
  description = "NextAuth.js URL"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

# -----------------------------------------------------------------------------
# OAuth Secrets
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "github_client_id" {
  name        = "${var.project}/${var.environment}/github-client-id"
  description = "GitHub OAuth Client ID"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "github_client_secret" {
  name        = "${var.project}/${var.environment}/github-client-secret"
  description = "GitHub OAuth Client Secret"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "gitlab_client_id" {
  name        = "${var.project}/${var.environment}/gitlab-client-id"
  description = "GitLab OAuth Client ID"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "gitlab_client_secret" {
  name        = "${var.project}/${var.environment}/gitlab-client-secret"
  description = "GitLab OAuth Client Secret"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "google_client_id" {
  name        = "${var.project}/${var.environment}/google-client-id"
  description = "Google OAuth Client ID"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "google_client_secret" {
  name        = "${var.project}/${var.environment}/google-client-secret"
  description = "Google OAuth Client Secret"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

# -----------------------------------------------------------------------------
# Payment Secrets
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "portone_imp_code" {
  name        = "${var.project}/${var.environment}/portone-imp-code"
  description = "PortOne merchant code"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "portone_channel_key" {
  name        = "${var.project}/${var.environment}/portone-channel-key"
  description = "PortOne channel key"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "portone_api_key" {
  name        = "${var.project}/${var.environment}/portone-api-key"
  description = "PortOne REST API key"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

resource "aws_secretsmanager_secret" "portone_api_secret" {
  name        = "${var.project}/${var.environment}/portone-api-secret"
  description = "PortOne REST API secret"

  tags = {
    Environment = var.environment
    Service     = "web-client"
  }
}

# -----------------------------------------------------------------------------
# Scanner & Agent Secrets
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "openai_api_key" {
  name        = "${var.project}/${var.environment}/openai-api-key"
  description = "OpenAI API key"

  tags = {
    Environment = var.environment
    Service     = "scanner-api"
  }
}

resource "aws_secretsmanager_secret" "supabase_url" {
  name        = "${var.project}/${var.environment}/supabase-url"
  description = "Supabase project URL"

  tags = {
    Environment = var.environment
    Service     = "scanner-api"
  }
}

resource "aws_secretsmanager_secret" "supabase_key" {
  name        = "${var.project}/${var.environment}/supabase-key"
  description = "Supabase service role key"

  tags = {
    Environment = var.environment
    Service     = "scanner-api"
  }
}
