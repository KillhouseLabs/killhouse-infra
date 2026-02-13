output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : var.alarm_sns_topic_arn
}
