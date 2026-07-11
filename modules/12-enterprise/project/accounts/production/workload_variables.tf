variable "database_subnet_ids" {
  description = "Private subnet IDs for database placement."
  type        = list(string)
}

variable "database_instance_class" {
  description = "RDS instance class for the environment."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_username" {
  description = "Example database username."
  type        = string
  default     = "app"
}

variable "database_password" {
  description = "Example database password. Use Secrets Manager in production workflows."
  type        = string
  sensitive   = true
}
