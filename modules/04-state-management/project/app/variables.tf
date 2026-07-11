variable "aws_region" {
  description = "AWS region for the sample application resources."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used for sample resource names."
  type        = string
  default     = "state-demo"
}

variable "environment" {
  description = "Environment name used in tags and names."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default = {
    Course = "terraform-production-engineering"
  }
}

