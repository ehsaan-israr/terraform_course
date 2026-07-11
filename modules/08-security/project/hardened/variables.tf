variable "aws_region" {
  description = "AWS region for the hardened example."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for the admin security group."
  type        = string
  default     = "vpc-00000000000000000"
}

variable "admin_cidrs" {
  description = "Approved administrator CIDR blocks. Use specific /32 addresses or VPN CIDRs."
  type        = list(string)
  default     = ["203.0.113.10/32"]
}

variable "db_secret_name" {
  description = "Name of an existing AWS Secrets Manager secret for database credentials."
  type        = string
  default     = "prod/example/db"
}

variable "bucket_name" {
  description = "Globally unique bucket name for secure application data."
  type        = string
  default     = "example-hardened-data-bucket"
}

