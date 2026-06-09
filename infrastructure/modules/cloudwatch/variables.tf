# infrastructure/modules/cloudwatch/variables.tf

variable "project_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "guardduty_detector_id" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
