# -----------------------------------------------------------------------------
# VPC Flow Logs
# -----------------------------------------------------------------------------

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  max_aggregation_interval = 60

  tags = {
    Name        = "${var.project}-vpc-flow-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/vpc/${var.project}/flow-logs"
  retention_in_days = 14

  tags = {
    Name        = "${var.project}-vpc-flow-logs"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# IAM Role for VPC Flow Logs
# -----------------------------------------------------------------------------

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}
