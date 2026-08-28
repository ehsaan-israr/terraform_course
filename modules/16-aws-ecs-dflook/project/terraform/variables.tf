# Shared inputs only. Environment differences come from terraform.workspace
# (see workspaces.tf), not from tfvars files.

variable "aws_region" {
  description = "AWS region for every workspace."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix. Workspace is appended (ecs-dflook-dev)."
  type        = string
  default     = "ecs-dflook"
}

variable "availability_zones" {
  description = "Availability zones used by public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "app_port" {
  description = "Container port registered with the ALB target group."
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Container image for the ECS service. Same image in every workspace unless you change this default."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "tags" {
  description = "Additional tags applied to resources. Environment is added from the workspace."
  type        = map(string)
  default = {
    Course = "terraform-production-engineering"
    Module = "16-aws-ecs-dflook"
  }
}
