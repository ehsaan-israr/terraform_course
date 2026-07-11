output "state_bucket_name" {
  description = "S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_region" {
  description = "AWS region for backend configuration."
  value       = var.aws_region
}

output "example_backend_config" {
  description = "Example terraform init backend flags for the app project."
  value = <<EOT
terraform init \
  -backend-config="bucket=${aws_s3_bucket.terraform_state.bucket}" \
  -backend-config="key=state-management/dev/terraform.tfstate" \
  -backend-config="region=${var.aws_region}" \
  -backend-config="dynamodb_table=${aws_dynamodb_table.terraform_locks.name}" \
  -backend-config="encrypt=true"
EOT
}

