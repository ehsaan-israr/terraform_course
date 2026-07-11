variable "name" {
  description = "Name prefix for RDS resources."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID attached to the database instance."
  type        = string
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database administrator username."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15"
}

variable "instance_class" {
  description = "RDS instance class. This creates billable resources."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated database storage in GiB."
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on destroy. Use false in production."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to RDS resources."
  type        = map(string)
  default     = {}
}

