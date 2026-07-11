variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource names."
  type        = string
  default     = "terraform-intermediate"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name used in names and tags."
  type        = string
  default     = "dev"
}

variable "servers" {
  description = "Map of server definitions. Keys become stable Terraform resource identities."
  type = map(object({
    instance_type = string
    role          = string
  }))

  default = {
    web-a = {
      instance_type = "t3.micro"
      role          = "web"
    }
    web-b = {
      instance_type = "t3.micro"
      role          = "web"
    }
    worker-a = {
      instance_type = "t3.micro"
      role          = "worker"
    }
  }
}

variable "ingress_rules" {
  description = "Named ingress rules rendered as dynamic blocks on the application security group."
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = {
    http = {
      description = "HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ssh = {
      description = "SSH from trusted documentation CIDR; replace before apply"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["203.0.113.10/32"]
    }
  }

  validation {
    condition = alltrue(flatten([
      for rule in values(var.ingress_rules) : [
        for cidr in rule.cidr_blocks : can(cidrhost(cidr, 0))
      ]
    ]))
    error_message = "Every ingress rule cidr_blocks entry must be a valid CIDR block."
  }
}

variable "create_elastic_ips" {
  description = "Whether to allocate and associate one Elastic IP per server."
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "admin_password" {
  description = "Demo sensitive value. In production, use AWS Secrets Manager or SSM Parameter Store instead."
  type        = string
  sensitive   = true
}
