output "vpc_id" {
  description = "Platform VPC ID."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS and RDS."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.app.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.app.name
}

output "app_bucket_name" {
  description = "Encrypted S3 bucket used by the application."
  value       = aws_s3_bucket.app.bucket
}

output "db_endpoint" {
  description = "Private RDS endpoint."
  value       = aws_db_instance.app.address
}

output "db_password_state_warning" {
  description = "Reminder that the generated password is in Terraform state."
  value       = "random_password.db.result is stored in Terraform state; protect your backend."
}

