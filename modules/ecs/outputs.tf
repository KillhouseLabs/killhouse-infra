output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "web_client_service_name" {
  description = "Web client ECS service name"
  value       = aws_ecs_service.web_client.name
}

output "scanner_api_service_name" {
  description = "Scanner API ECS service name"
  value       = aws_ecs_service.scanner_api.name
}

output "ecs_execution_role_arn" {
  description = "ECS execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}
