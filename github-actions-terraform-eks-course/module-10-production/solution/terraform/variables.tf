variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "gha-terraform-eks"
}

variable "environment" {
  type        = string
  description = "dev, staging, or prod"
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "lock_table_name" {
  type    = string
  default = "terraform-state-lock"
}

variable "ecr_repository_name" {
  type    = string
  default = "sample-app"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
