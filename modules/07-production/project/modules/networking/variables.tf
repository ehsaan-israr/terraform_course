variable "name_prefix" {
  description = "Prefix used for named networking resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for public subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to all supported resources."
  type        = map(string)
  default     = {}
}

