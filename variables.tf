variable "pagerduty_token" {
  type        = string
  description = "Pagerduty API token"
}

variable "cluster_name" {
  type        = string
  description = "Name of cluster to register inside Pagerduty"
}

variable "escalation_policy" {
  type        = string
  description = "Name of the escalation policy to use"
}
