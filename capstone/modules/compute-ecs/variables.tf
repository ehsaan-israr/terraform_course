variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "container_image" { type = string }
variable "container_port" {
  type    = number
  default = 8080
}
variable "desired_count" {
  type    = number
  default = 2
}
variable "cpu" {
  type    = number
  default = 512
}
variable "memory" {
  type    = number
  default = 1024
}
variable "environment_variables" {
  type    = map(string)
  default = {}
}
variable "secrets" {
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}
variable "health_check_path" {
  type    = string
  default = "/health"
}
variable "tags" {
  type    = map(string)
  default = {}
}
