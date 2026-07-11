output "artifact_bucket_name" {
  description = "Name of the sample application artifact bucket."
  value       = aws_s3_bucket.app_artifacts.bucket
}

output "artifact_bucket_arn" {
  description = "ARN of the sample application artifact bucket."
  value       = aws_s3_bucket.app_artifacts.arn
}

