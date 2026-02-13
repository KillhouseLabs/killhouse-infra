# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-alb-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# ECS Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "ecs" {
  name        = "${var.project}-ecs-sg"
  description = "Security group for ECS services"
  vpc_id      = aws_vpc.main.id

  # web-client port from ALB
  ingress {
    description     = "web-client from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # scanner-api port from ALB
  ingress {
    description     = "scanner-api from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Internal communication within VPC
  ingress {
    description = "Internal VPC communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Outbound HTTPS (OpenAI, Supabase, etc.)
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound PostgreSQL (Supabase)
  egress {
    description = "PostgreSQL outbound"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to exploit-agent
  egress {
    description     = "To exploit-agent"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.agent.id]
  }

  tags = {
    Name        = "${var.project}-ecs-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Exploit Agent Security Group (Sandbox)
# -----------------------------------------------------------------------------

resource "aws_security_group" "agent" {
  name        = "${var.project}-agent-sg"
  description = "Security group for Exploit Agent (sandbox)"
  vpc_id      = aws_vpc.main.id

  # API port from ECS
  ingress {
    description     = "API from ECS scanner"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  # SSH for debugging (restrict to admin IP in production)
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

  # Outbound HTTPS (OpenAI only)
  egress {
    description = "HTTPS outbound (OpenAI)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-agent-sg"
    Environment = var.environment
  }
}
