# -----------------------------------------------------------------------------
# k3s Cluster Module - 3 Node HA with Embedded etcd + gVisor
# -----------------------------------------------------------------------------

# Data source: Amazon Linux 2023 AMI
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

data "aws_vpc" "selected" {
  id = var.vpc_id
}

# -----------------------------------------------------------------------------
# SSM Parameter to share k3s token across nodes
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "k3s_token" {
  name        = "/${var.project}/${var.environment}/k3s-token"
  description = "k3s cluster join token"
  type        = "SecureString"
  value       = var.k3s_token

  tags = {
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Security Group for k3s cluster
# -----------------------------------------------------------------------------

resource "aws_security_group" "k3s" {
  name        = "${var.project}-${var.environment}-k3s-sg"
  description = "Security group for k3s cluster nodes"
  vpc_id      = var.vpc_id

  # k3s API server (cluster internal)
  ingress {
    description = "k3s API server (cluster)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  # k3s API server (NLB health check + external access via NLB)
  ingress {
    description = "k3s API via NLB"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # etcd
  ingress {
    description = "etcd client and peer"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  # kubelet
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  # Flannel VXLAN
  ingress {
    description = "Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
  }

  # k3s metrics
  ingress {
    description = "kube-controller-manager metrics"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "kube-scheduler metrics"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    self        = true
  }

  # NodePort range for services
  ingress {
    description = "NodePort services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    self        = true
  }

  # HTTP/HTTPS ingress from VPC (for Traefik/ingress controller)
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # SSH (optional, for debugging)
  dynamic "ingress" {
    for_each = var.allowed_ssh_cidr != "" ? [1] : []
    content {
      description = "SSH from admin"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.allowed_ssh_cidr]
    }
  }

  # All egress (ECR, packages, etc.)
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-k3s-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# IAM Role for k3s nodes
# -----------------------------------------------------------------------------

resource "aws_iam_role" "k3s_node" {
  name = "${var.project}-${var.environment}-k3s-node-role"

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
    Name        = "${var.project}-${var.environment}-k3s-node-role"
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "k3s_node" {
  name = "${var.project}-${var.environment}-k3s-node-profile"
  role = aws_iam_role.k3s_node.name
}

# ECR pull policy
resource "aws_iam_role_policy" "ecr_pull" {
  name = "${var.project}-${var.environment}-k3s-ecr-policy"
  role = aws_iam_role.k3s_node.id

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

# Secrets Manager read policy
resource "aws_iam_role_policy" "secrets_read" {
  name = "${var.project}-${var.environment}-k3s-secrets-policy"
  role = aws_iam_role.k3s_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.secret_arns
      }
    ]
  })
}

# SSM policy (for Session Manager access + parameter read)
resource "aws_iam_role_policy" "ssm" {
  name = "${var.project}-${var.environment}-k3s-ssm-policy"
  role = aws_iam_role.k3s_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:UpdateInstanceInformation",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Logs policy
resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.project}-${var.environment}-k3s-logs-policy"
  role = aws_iam_role.k3s_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/ec2/${var.project}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# k3s server nodes
# -----------------------------------------------------------------------------

resource "aws_instance" "k3s_server" {
  count = var.node_count

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  iam_instance_profile   = aws_iam_instance_profile.k3s_node.name
  vpc_security_group_ids = [aws_security_group.k3s.id]

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    is_init_node = count.index == 0
    k3s_version  = var.k3s_version
    k3s_token    = var.k3s_token
    init_node_ip = count.index == 0 ? "" : aws_instance.k3s_server[0].private_ip
    node_name    = "${var.project}-${var.environment}-k3s-${count.index}"
    region       = var.region
    ecr_registry = var.ecr_registry_url
    project      = var.project
    environment  = var.environment
  }))

  tags = {
    Name        = "${var.project}-${var.environment}-k3s-${count.index}"
    Environment = var.environment
    Role        = count.index == 0 ? "k3s-init" : "k3s-server"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }

  depends_on = [aws_ssm_parameter.k3s_token]
}

# -----------------------------------------------------------------------------
# NLB for k3s API endpoint (nodes are in private subnets)
# -----------------------------------------------------------------------------

resource "aws_lb" "k3s_api" {
  name               = "${var.project}-${var.environment}-k3s-api"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-k3s-api-nlb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "k3s_api" {
  name     = "${var.project}-${var.environment}-k3s-api"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "TCP"
    port                = 6443
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_target_group_attachment" "k3s_api" {
  count            = var.node_count
  target_group_arn = aws_lb_target_group.k3s_api.arn
  target_id        = aws_instance.k3s_server[count.index].id
  port             = 6443
}

resource "aws_lb_listener" "k3s_api" {
  load_balancer_arn = aws_lb.k3s_api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_api.arn
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "k3s" {
  name              = "/ec2/${var.project}/k3s"
  retention_in_days = 30

  tags = {
    Environment = var.environment
  }
}
