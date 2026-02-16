# -----------------------------------------------------------------------------
# App Security Group (EC2 with Caddy + all services)
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "Security group for app EC2 (Caddy + Docker Compose services)"
  vpc_id      = aws_vpc.main.id

  # HTTP from anywhere (Caddy → redirect to HTTPS)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere (Caddy TLS termination)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH for debugging (restrict to admin IP)
  dynamic "ingress" {
    for_each = var.admin_cidr != "" ? [1] : []
    content {
      description = "SSH from admin"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.admin_cidr]
    }
  }

  # HTTPS outbound (OpenAI, Supabase, ECR, ACME, etc.)
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound (package managers, ACME HTTP challenge)
  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL outbound (Supabase)
  egress {
    description = "PostgreSQL outbound"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-app-sg"
    Environment = var.environment
  }
}
