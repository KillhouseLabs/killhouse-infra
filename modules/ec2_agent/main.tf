# -----------------------------------------------------------------------------
# EC2 Instance for Exploit Agent (Docker-in-Docker)
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

resource "aws_instance" "exploit_agent" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.agent_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.agent.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ecr_registry_url       = var.ecr_registry_url
    exploit_agent_image    = var.exploit_agent_image
    exploit_sandbox_image  = var.exploit_sandbox_image
    region                 = var.region
    openai_secret_arn      = var.openai_api_key_secret_arn
    supabase_url_secret_arn = var.supabase_url_secret_arn
    supabase_key_secret_arn = var.supabase_key_secret_arn
  }))

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project}-exploit-agent"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# IAM Role for EC2
# -----------------------------------------------------------------------------

resource "aws_iam_role" "agent" {
  name = "${var.project}-exploit-agent-role"

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

resource "aws_iam_instance_profile" "agent" {
  name = "${var.project}-exploit-agent-profile"
  role = aws_iam_role.agent.name
}

# ECR pull permission
resource "aws_iam_role_policy" "agent_ecr" {
  name = "${var.project}-agent-ecr-policy"
  role = aws_iam_role.agent.id

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
resource "aws_iam_role_policy" "agent_secrets" {
  name = "${var.project}-agent-secrets-policy"
  role = aws_iam_role.agent.id

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
resource "aws_iam_role_policy" "agent_logs" {
  name = "${var.project}-agent-logs-policy"
  role = aws_iam_role.agent.id

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

# SSM for debugging (optional)
resource "aws_iam_role_policy_attachment" "agent_ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "agent" {
  name              = "/ec2/${var.project}/exploit-agent"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
  }
}
