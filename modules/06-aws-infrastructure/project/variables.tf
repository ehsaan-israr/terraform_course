variable "aws_region" {
  description = "AWS region for the platform skeleton."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for platform resources."
  type        = string
  default     = "platform-skeleton"
}

variable "environment" {
  description = "Environment label for names and tags."
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the platform VPC."
  type        = string
  default     = "10.60.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["10.60.0.0/24", "10.60.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["10.60.10.0/24", "10.60.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnet egress. NAT gateways have hourly and data processing cost."
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Application container port exposed through the ALB."
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Container image used by the ECS service stub."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "ecs_desired_count" {
  description = "Desired ECS task count. Fargate tasks are billable while running."
  type        = number
  default     = 1
}

variable "db_username" {
  description = "Database administrator username."
  type        = string
  default     = "appadmin"
}

variable "db_instance_class" {
  description = "RDS instance class. RDS instances are billable."
  type        = string
  default     = "db.t3.micro"
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default = {
    Course = "terraform-production-engineering"
  }
}

