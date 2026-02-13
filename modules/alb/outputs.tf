output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = aws_lb.main.zone_id
}

output "web_client_target_group_arn" {
  description = "Web client target group ARN"
  value       = aws_lb_target_group.web_client.arn
}

output "scanner_api_target_group_arn" {
  description = "Scanner API target group ARN"
  value       = aws_lb_target_group.scanner_api.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = aws_lb_listener.https.arn
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}
