variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used in resource names and tags."
  type        = string
  default     = "iac-fundamentals"
}

variable "environment" {
  description = "Environment name used for tags."
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name. S3 bucket names are global across all AWS accounts."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is free-tier eligible in many AWS accounts; use t2.micro if your account/region requires it."
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr_block" {
  description = "CIDR block allowed to SSH to the instance. Use your public IP with /32. Example: 203.0.113.10/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr_block, 0))
    error_message = "ssh_cidr_block must be a valid CIDR block, for example 203.0.113.10/32."
  }
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH access. Leave null if you only need the HTTP demo."
  type        = string
  default     = null
}
