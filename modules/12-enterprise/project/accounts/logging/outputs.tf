output "log_archive_bucket" {
  value = aws_s3_bucket.log_archive.id
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.organization.arn
}
