# infrastructure/environments/dev/variables.tf
# No defaults here — all values are set in terraform.tfvars

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
}

variable "project_name" {
  type        = string
  description = "Prefix used for all resource names"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev / staging / prod)"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for EKS worker nodes"
}

variable "node_min" {
  type        = number
  description = "Minimum number of worker nodes"
}

variable "node_max" {
  type        = number
  description = "Maximum number of worker nodes"
}

variable "node_desired" {
  type        = number
  description = "Desired number of worker nodes at launch"
}

variable "guardduty_finding_frequency" {
  type        = string
  description = "How often GuardDuty publishes findings (FIFTEEN_MINUTES | ONE_HOUR | SIX_HOURS)"
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log group retention in days"
}

variable "alert_email" {
  type        = string
  description = "Email address to receive GuardDuty SNS alerts"
}
