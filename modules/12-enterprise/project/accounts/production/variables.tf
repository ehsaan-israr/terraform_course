variable "account_id" {
  description = "Target AWS account ID."
  type        = string
}

variable "region" {
  description = "AWS region for regional resources."
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Deployment role name to assume in the target account."
  type        = string
  default     = "TerraformExecutionRole"
}

variable "name_prefix" {
  description = "Prefix used for account resources."
  type        = string
}
