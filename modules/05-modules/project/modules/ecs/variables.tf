variable "name" {
  description = "Name prefix for ECS resources."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where Fargate tasks should run."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to ECS tasks."
  type        = string
}

variable "container_image" {
  description = "Container image for the sample task definition."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_port" {
  description = "Container port exposed by the sample task."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired ECS service task count."
  type        = number
  default     = 1
}

variable "create_service" {
  description = "Whether to create the ECS service. Keep false in labs unless networking and image access are ready."
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Whether Fargate tasks receive public IPs."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to ECS resources."
  type        = map(string)
  default     = {}
}

