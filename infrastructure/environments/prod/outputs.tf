# infrastructure/environments/dev/outputs.tf

output "cluster_name"       { value = module.eks.cluster_name }
output "cluster_endpoint"   { value = module.eks.cluster_endpoint }
output "vpc_id"             { value = module.vpc.vpc_id }
output "guardduty_detector" { value = module.guardduty.detector_id }
output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${module.cloudwatch.dashboard_name}"
}
