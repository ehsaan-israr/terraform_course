variable "aws_region" {
  description = "AWS region for the composed module example."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix used by all modules."
  type        = string
  default     = "module-course"
}

variable "environment" {
  description = "Environment name used for tags and resource names."
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.50.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used for public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["10.50.0.0/24", "10.50.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["10.50.10.0/24", "10.50.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnet egress. NAT gateways have hourly and data processing cost."
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Container/application port allowed from the load balancer security group."
  type        = number
  default     = 8080
}

variable "db_username" {
  description = "Database administrator username for the educational RDS module."
  type        = string
  default     = "appadmin"
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default = {
    Course = "terraform-production-engineering"
  }
}

