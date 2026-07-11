output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "versioning_status" {
  description = "Configured S3 versioning status."
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}

output "encryption_algorithm" {
  description = "Configured default encryption algorithm."
  value       = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
}

