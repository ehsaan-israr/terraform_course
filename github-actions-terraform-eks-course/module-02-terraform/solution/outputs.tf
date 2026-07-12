output "bucket_id" {
  description = "The name (ID) of the S3 bucket."
  value       = module.storage.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = module.storage.bucket_arn
}

output "bucket_region" {
  description = "The AWS region of the S3 bucket."
  value       = var.aws_region
}

output "versioning_status" {
  description = "Versioning status of the S3 bucket."
  value       = module.storage.versioning_status
}

output "workspace" {
  description = "Active Terraform workspace."
  value       = terraform.workspace
}
