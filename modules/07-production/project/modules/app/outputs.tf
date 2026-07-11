output "web_security_group_id" {
  description = "ID of the application web security group."
  value       = aws_security_group.web.id
}

output "artifact_bucket_name" {
  description = "Name of the application artifact bucket."
  value       = aws_s3_bucket.artifacts.bucket
}

