# infrastructure/environments/dev/main.tf

locals {
  project = var.project_name
  env     = var.environment
  tags = {
    Project     = local.project
    Environment = local.env
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source       = "../../modules/vpc"
  project_name = local.project
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
  tags         = local.tags
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = var.cluster_name
  k8s_version        = var.k8s_version
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnets
  node_instance_type = var.node_instance_type
  node_min           = var.node_min
  node_max           = var.node_max
  node_desired       = var.node_desired
  tags               = local.tags
}

module "guardduty" {
  source            = "../../modules/guardduty"
  project_name      = local.project
  finding_frequency = var.guardduty_finding_frequency
  alert_email       = var.alert_email
  tags              = local.tags
}

module "cloudwatch" {
  source                 = "../../modules/cloudwatch"
  project_name           = local.project
  cluster_name           = var.cluster_name
  guardduty_detector_id  = module.guardduty.detector_id
  sns_topic_arn          = module.guardduty.sns_topic_arn
  log_retention_days     = var.log_retention_days
  tags                   = local.tags
}
