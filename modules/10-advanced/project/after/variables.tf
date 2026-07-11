variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "advanced-refactor"
}

variable "ami_id" {
  type        = string
  description = "AMI used by the example EC2 instance."
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
