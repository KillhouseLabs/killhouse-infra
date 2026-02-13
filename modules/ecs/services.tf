# -----------------------------------------------------------------------------
# Web Client Service
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "web_client" {
  name            = "web-client"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_client.arn
  desired_count   = var.web_client_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.web_client_target_group_arn
    container_name   = "web-client"
    container_port   = 3000
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Scanner API Service
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "scanner_api" {
  name            = "scanner-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.scanner_api.arn
  desired_count   = var.scanner_api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.scanner_api_target_group_arn
    container_name   = "scanner-api"
    container_port   = 8080
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Environment = var.environment
  }
}
