variable "aws_region" {
  description = "AWS region for prod."
  type        = string
  default     = "us-east-1"
}

variable "active_color" {
  description = "Active deployment color for blue/green demonstrations."
  type        = string
  default     = "blue"
}

