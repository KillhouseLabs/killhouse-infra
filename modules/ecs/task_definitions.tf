# -----------------------------------------------------------------------------
# Web Client Task Definition
# -----------------------------------------------------------------------------

resource "aws_ecs_task_definition" "web_client" {
  family                   = "${var.project}-web-client"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.web_client_cpu
  memory                   = var.web_client_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "web-client"
      image     = "${var.web_client_image}:${var.web_client_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "NODE_ENV", value = var.environment == "prod" ? "production" : "development" },
        { name = "PORT", value = "3000" }
      ]

      secrets = [
        { name = "DATABASE_URL", valueFrom = var.database_url_secret_arn },
        { name = "DIRECT_URL", valueFrom = var.direct_url_secret_arn },
        { name = "AUTH_SECRET", valueFrom = var.auth_secret_arn },
        { name = "AUTH_URL", valueFrom = var.auth_url_secret_arn },
        { name = "GITHUB_CLIENT_ID", valueFrom = var.github_client_id_secret_arn },
        { name = "GITHUB_CLIENT_SECRET", valueFrom = var.github_client_secret_secret_arn },
        { name = "NEXT_PUBLIC_IMP_CODE", valueFrom = var.portone_imp_code_secret_arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web_client.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Scanner API Task Definition
# -----------------------------------------------------------------------------

resource "aws_ecs_task_definition" "scanner_api" {
  family                   = "${var.project}-scanner-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.scanner_api_cpu
  memory                   = var.scanner_api_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "scanner-api"
      image     = "${var.scanner_api_image}:${var.scanner_api_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "ENVIRONMENT", value = var.environment },
        { name = "PORT", value = "8080" },
        { name = "EXPLOIT_AGENT_URL", value = "http://${var.exploit_agent_private_ip}:8081" }
      ]

      secrets = [
        { name = "OPENAI_API_KEY", valueFrom = var.openai_api_key_secret_arn },
        { name = "SUPABASE_URL", valueFrom = var.supabase_url_secret_arn },
        { name = "SUPABASE_KEY", valueFrom = var.supabase_key_secret_arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.scanner_api.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Environment = var.environment
  }
}
