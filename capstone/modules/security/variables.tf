variable "name" { type = string }
variable "waf_scope" {
  type    = string
  default = "CLOUDFRONT"
}
variable "secret_names" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
