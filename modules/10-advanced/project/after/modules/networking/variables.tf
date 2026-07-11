variable "project" { type = string }
variable "aws_region" { type = string }
variable "cidr_block" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
