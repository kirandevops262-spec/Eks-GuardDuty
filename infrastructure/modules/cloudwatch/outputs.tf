# infrastructure/modules/cloudwatch/outputs.tf

output "app_log_group_name"    { value = aws_cloudwatch_log_group.eks_app.name }
output "mcp_log_group_name"    { value = aws_cloudwatch_log_group.mcp_server.name }
output "dashboard_name"        { value = aws_cloudwatch_dashboard.main.dashboard_name }
