# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

# App EC2 Status Check
resource "aws_cloudwatch_metric_alarm" "app_status_check" {
  alarm_name          = "${var.project}-app-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "App EC2 instance status check failed"
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = var.app_instance_id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = {
    Environment = var.environment
  }
}

# App EC2 CPU High
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${var.project}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "App EC2 CPU utilization exceeded 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.app_instance_id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = {
    Environment = var.environment
  }
}

# App EC2 Memory High
resource "aws_cloudwatch_metric_alarm" "app_memory_high" {
  alarm_name          = "${var.project}-${var.environment}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Memory usage exceeds 85%"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alarms[0].arn] : (var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : [])

  dimensions = {
    InstanceId = var.app_instance_id
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# App EC2 Disk High
resource "aws_cloudwatch_metric_alarm" "app_disk_high" {
  alarm_name          = "${var.project}-${var.environment}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Disk usage exceeds 80%"
  alarm_actions       = var.create_sns_topic ? [aws_sns_topic.alarms[0].arn] : (var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : [])

  dimensions = {
    InstanceId = var.app_instance_id
    path       = "/"
    fstype     = "xfs"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          region = var.region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.app_instance_id]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 Network In/Out"
          region = var.region
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", var.app_instance_id],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.app_instance_id]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "EC2 Disk Read/Write"
          region = var.region
          metrics = [
            ["AWS/EC2", "DiskReadBytes", "InstanceId", var.app_instance_id],
            ["AWS/EC2", "DiskWriteBytes", "InstanceId", var.app_instance_id]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "EC2 Status Check"
          region = var.region
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", var.app_instance_id],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", var.app_instance_id],
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", var.app_instance_id]
          ]
          period = 300
          stat   = "Maximum"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# SNS Topic for Alarms (optional)
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project}-alarms"

  tags = {
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns_topic && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
