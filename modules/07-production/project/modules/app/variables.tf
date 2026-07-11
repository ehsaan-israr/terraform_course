variable "name_prefix" {
  description = "Prefix used for application resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the application security group is created."
  type        = string
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to reach HTTP. Use load balancer CIDRs or managed prefix lists in real systems."
  type        = list(string)
}

variable "active_color" {
  description = "Current active deployment color."
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be blue or green."
  }
}

variable "tags" {
  description = "Common tags applied to all supported resources."
  type        = map(string)
  default     = {}
}

