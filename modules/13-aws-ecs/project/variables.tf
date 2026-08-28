variable "aws_region" {
  description = "AWS region for the ECS lab."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for ECS lab resources."
  type        = string
  default     = "ecs-lab"
}

variable "environment" {
  description = "Environment label for names and tags."
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.70.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["10.70.0.0/24", "10.70.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["10.70.10.0/24", "10.70.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnet egress. NAT gateways have hourly cost."
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Container port registered with the ALB target group."
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Container image for the ECS service. Public nginx avoids needing ECR for the first lab."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "ecs_desired_count" {
  description = "Desired Fargate task count. Tasks are billable while running. Use 0 for plan-only labs."
  type        = number
  default     = 1

  validation {
    condition     = var.ecs_desired_count >= 0 && var.ecs_desired_count <= 4
    error_message = "Keep desired count between 0 and 4 in this lab."
  }
}

variable "assign_public_ip" {
  description = "Assign public IPs to tasks. true is a lab shortcut so tasks can pull images without NAT. Production should be false with private subnets plus NAT or VPC endpoints."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default = {
    Course = "terraform-production-engineering"
    Module = "13-aws-ecs"
  }
}
