# infrastructure/modules/cloudwatch/main.tf

# Log Groups
resource "aws_cloudwatch_log_group" "eks_app" {
  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "mcp_server" {
  name              = "/eks-mcp/mcp-server"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "EKS Node CPU Utilization"
          metrics = [["ContainerInsights", "node_cpu_utilization", "ClusterName", var.cluster_name]]
          period = 300
          stat   = "Average"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "EKS Node Memory Utilization"
          metrics = [["ContainerInsights", "node_memory_utilization", "ClusterName", var.cluster_name]]
          period = 300
          stat   = "Average"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "GuardDuty Findings Count"
          metrics = [["AWS/GuardDuty", "FindingsCount", "DetectorId", var.guardduty_detector_id]]
          period = 3600
          stat   = "Sum"
          view   = "timeSeries"
        }
      }
    ]
  })
}

# Alarm — High CPU on EKS nodes
resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.cluster_name}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node CPU > 80%"
  alarm_actions       = [var.sns_topic_arn]
  dimensions          = { ClusterName = var.cluster_name }
  tags                = var.tags
}

# Alarm — GuardDuty High Severity findings
resource "aws_cloudwatch_metric_alarm" "guardduty_high_findings" {
  alarm_name          = "${var.project_name}-guardduty-high-severity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  alarm_description   = "GuardDuty HIGH severity finding detected"
  alarm_actions       = [var.sns_topic_arn]

  metric_query {
    id          = "findings"
    return_data = true
    metric {
      metric_name = "FindingsCount"
      namespace   = "AWS/GuardDuty"
      period      = 300
      stat        = "Sum"
      dimensions  = { DetectorId = var.guardduty_detector_id }
    }
  }
  tags = var.tags
}
