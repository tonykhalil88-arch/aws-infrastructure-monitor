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