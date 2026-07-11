variable "name" { type = string }
variable "origin_domain_name" { type = string }
variable "domain_aliases" {
  type    = list(string)
  default = []
}
variable "certificate_arn" {
  type    = string
  default = ""
}
variable "web_acl_id" {
  type    = string
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
