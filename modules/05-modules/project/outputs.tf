output "vpc_id" {
  description = "VPC ID from the VPC module."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs from the VPC module."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs from the VPC module."
  value       = module.vpc.private_subnet_ids
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "rds_endpoint" {
  description = "RDS endpoint address."
  value       = module.rds.db_endpoint
}

output "rds_password_secret_note" {
  description = "Reminder that the generated password is stored in Terraform state."
  value       = "The RDS module uses random_password for education; protect state as a secret."
}

