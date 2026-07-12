output "bucket_name" {
  description = "Name of the S3 bucket created by this project."
  value       = aws_s3_bucket.app.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.app.arn
}

output "instance_id" {
  description = "EC2 instance ID recorded by LocalStack."
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IPv4 address returned by LocalStack."
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP URL derived from LocalStack outputs. LocalStack does not run a real Apache server."
  value       = "http://${coalesce(aws_instance.web.public_dns, aws_instance.web.public_ip, "pending")}"
}

output "vpc_id" {
  description = "VPC created for the LocalStack lab."
  value       = aws_vpc.local.id
}
