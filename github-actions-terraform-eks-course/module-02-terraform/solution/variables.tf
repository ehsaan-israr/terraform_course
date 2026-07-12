variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "project_name" {
  description = "Project name used in resource naming and tags."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "bucket_suffix" {
  description = "Unique suffix appended to the S3 bucket name to ensure global uniqueness."
  type        = string
  default     = "course"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,12}$", var.bucket_suffix))
    error_message = "bucket_suffix must be 3-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "common_tags" {
  description = "Additional tags merged with required Environment, Project, and ManagedBy tags."
  type        = map(string)
  default     = {}
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.common_tags)
}
