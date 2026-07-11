output "alb_security_group_id" {
  description = "Security group ID for a public load balancer."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for application compute."
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "Security group ID for the database tier."
  value       = aws_security_group.database.id
}

