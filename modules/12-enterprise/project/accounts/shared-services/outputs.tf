output "ecr_repository_url" {
  value = aws_ecr_repository.platform.repository_url
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.id
}
