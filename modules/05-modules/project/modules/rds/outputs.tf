output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "RDS endpoint address."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS database port."
  value       = aws_db_instance.this.port
}

output "db_subnet_group_name" {
  description = "DB subnet group name."
  value       = aws_db_subnet_group.this.name
}

output "generated_password" {
  description = "Generated database password. Sensitive, but still stored in Terraform state."
  value       = random_password.master.result
  sensitive   = true
}

