variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "gha-terraform-eks"
}

variable "environment" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.28"
}

variable "node_count" {
  type = number
}

variable "instance_types" {
  type = list(string)
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
