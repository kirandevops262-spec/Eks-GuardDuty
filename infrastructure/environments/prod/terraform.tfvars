# infrastructure/environments/dev/terraform.tfvars
# Edit these values before running terraform apply

aws_region   = "us-east-1"
project_name = "eks-mcp"
environment  = "prod"
cluster_name = "eks-mcp-cluster"
vpc_cidr     = "10.0.0.0/16"

k8s_version        = "1.35"
node_instance_type = "t3.medium"
node_min           = 2
node_max           = 4
node_desired       = 2

guardduty_finding_frequency = "SIX_HOURS"
log_retention_days          = 30
alert_email                 = ""   # Set your email to get GuardDuty alerts
