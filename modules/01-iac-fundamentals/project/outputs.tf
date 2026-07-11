output "bucket_name" {
  description = "Name of the S3 bucket created by this project."
  value       = aws_s3_bucket.app.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.app.arn
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IPv4 address of the EC2 instance."
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP URL for the demo web server."
  value       = "http://${aws_instance.web.public_dns}"
}
