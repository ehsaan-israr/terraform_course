variable "aws_region" {
  description = "Region sent to the AWS provider. LocalStack mostly ignores real region constraints."
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
  description = "S3 bucket name for the LocalStack demo."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type recorded by LocalStack."
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr_block" {
  description = "CIDR block allowed to SSH in the security group."
  type        = string
  default     = "203.0.113.10/32"

  validation {
    condition     = can(cidrhost(var.ssh_cidr_block, 0))
    error_message = "ssh_cidr_block must be a valid CIDR block, for example 203.0.113.10/32."
  }
}

variable "key_name" {
  description = "Optional EC2 key pair name. Leave null for LocalStack demos."
  type        = string
  default     = null
}

variable "localstack_endpoint" {
  description = "LocalStack edge endpoint."
  type        = string
  default     = "http://localhost:4566"
}

variable "localstack_ami_id" {
  description = "Optional AMI override. Leave null to use the AMI registered by localstack-init (name: al2023-ami-localstack)."
  type        = string
  default     = null
}
