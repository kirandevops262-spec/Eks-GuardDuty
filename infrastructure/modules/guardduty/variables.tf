# infrastructure/modules/guardduty/variables.tf

variable "project_name" {
  type = string
}

variable "finding_frequency" {
  type    = string
  default = "SIX_HOURS"
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
