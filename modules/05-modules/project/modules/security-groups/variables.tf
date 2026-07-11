variable "name" {
  description = "Name prefix for security groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created."
  type        = string
}

variable "app_port" {
  description = "Application port allowed from the ALB security group."
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port allowed from the application security group."
  type        = number
  default     = 5432
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on HTTP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags applied to security groups."
  type        = map(string)
  default     = {}
}

