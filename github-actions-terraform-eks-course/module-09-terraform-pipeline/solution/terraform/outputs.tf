output "state_bucket_name" {
  description = "Terraform remote state S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Terraform state lock DynamoDB table"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions_terraform.arn
}

output "app_artifacts_bucket" {
  description = "Application artifacts bucket created by pipeline"
  value       = aws_s3_bucket.app_artifacts.id
}

output "cluster_name_parameter" {
  description = "SSM parameter storing cluster name"
  value       = aws_ssm_parameter.cluster_name.name
}
