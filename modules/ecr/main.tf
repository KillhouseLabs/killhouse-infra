# -----------------------------------------------------------------------------
# ECR Repositories
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "web_client" {
  name                 = "${var.project}/web-client"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project}-web-client"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "scanner_api" {
  name                 = "${var.project}/scanner-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project}-scanner-api"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "exploit_agent" {
  name                 = "${var.project}/exploit-agent"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project}-exploit-agent"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "exploit_sandbox" {
  name                 = "${var.project}/exploit-sandbox"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project}-exploit-sandbox"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Policy (keep last 10 images)
# -----------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = toset([
    aws_ecr_repository.web_client.name,
    aws_ecr_repository.scanner_api.name,
    aws_ecr_repository.exploit_agent.name,
    aws_ecr_repository.exploit_sandbox.name,
  ])
  repository = each.value

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
