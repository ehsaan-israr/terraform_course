variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource naming and tags"
  type        = string
  default     = "gha-terraform-eks"
}

variable "environment" {
  description = "Deployment environment label"
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state (bootstrap)"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "github_org" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "allowed_branches" {
  description = "GitHub refs allowed to assume the Terraform IAM role"
  type        = list(string)
  default     = ["main"]
}

variable "cluster_name" {
  description = "EKS cluster name placeholder for pipeline demo"
  type        = string
  default     = "module09-eks"
}
