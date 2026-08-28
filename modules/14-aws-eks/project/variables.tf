variable "aws_region" {
  description = "AWS region for the EKS lab."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for EKS lab resources."
  type        = string
  default     = "eks-lab"
}

variable "environment" {
  description = "Environment label for names and tags."
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the lab VPC. Keep it large enough for pod IPs."
  type        = string
  default     = "10.80.0.0/16"
}

variable "availability_zones" {
  description = "Two AZs are required for EKS."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ (load balancers, NAT)."
  type        = list(string)
  default     = ["10.80.0.0/24", "10.80.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per AZ (nodes and pods)."
  type        = list(string)
  default     = ["10.80.10.0/24", "10.80.11.0/24"]
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane. Pin this."
  type        = string
  default     = "1.31"
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private nodes can pull images. Hourly cost."
  type        = bool
  default     = false
}

variable "enable_node_group" {
  description = "Create a managed node group. Extra EC2 cost. Leave false unless you will destroy the same day."
  type        = bool
  default     = false
}

variable "node_instance_types" {
  description = "Instance types for the optional managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default = {
    Course = "terraform-production-engineering"
    Module = "14-aws-eks"
  }
}
