variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-monitor"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "Email address to send alerts to"
  type        = string
}
variable "billing_threshold" {
  description = "USD amount to trigger billing alarm"
  type        = number
  default     = 10
}