# -----------------------------------------------------------------------------
# VPC Endpoints
# -----------------------------------------------------------------------------
# Interface endpoints (~$7/mo each): ECR API, ECR DKR, Secrets Manager, CloudWatch Logs
# Gateway endpoint (free): S3
# Set enable_vpc_endpoints = false in dev to save ~$28/mo.
# -----------------------------------------------------------------------------

# Security group for VPC Endpoints (HTTPS from VPC CIDR)
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name        = "${var.project}-vpce-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name        = "${var.project}-vpce-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Interface Endpoints
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-ecr-api-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-ecr-dkr-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-secretsmanager-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "logs" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-logs-endpoint"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Gateway Endpoint (free)
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id],
    [aws_route_table.private.id]
  )

  tags = {
    Name        = "${var.project}-s3-endpoint"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Data source for current region
# -----------------------------------------------------------------------------

data "aws_region" "current" {}
