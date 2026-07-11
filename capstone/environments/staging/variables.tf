variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "capstone-platform"
}

variable "environment" {
  type = string
}

variable "container_image" {
  type = string
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "redis_auth_token" {
  type      = string
  default   = null
  sensitive = true
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "app_environment_variables" {
  type    = map(string)
  default = {}
}
