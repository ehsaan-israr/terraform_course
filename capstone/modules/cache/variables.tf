variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}
variable "node_count" {
  type    = number
  default = 1
}
variable "auth_token" {
  type      = string
  default   = null
  sensitive = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
