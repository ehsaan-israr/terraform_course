variable "zone_id" {
  type    = string
  default = ""
}
variable "records" {
  type = map(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  default = {}
}
