variable "aws_region" {
  description = "AWS region where the backend resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used for the state bucket and lock table names."
  type        = string
  default     = "terraform-course"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}[a-z0-9]$", var.name_prefix))
    error_message = "Use 3-42 lowercase letters, numbers, and hyphens. Start and end with a letter or number."
  }
}

variable "environment" {
  description = "Environment label used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "force_destroy_state_bucket" {
  description = "Set true only in disposable lab accounts to allow deleting a non-empty state bucket."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to backend resources."
  type        = map(string)
  default = {
    Course = "terraform-production-engineering"
  }
}

