output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.web.id
}

output "elastic_ip" {
  description = "Elastic IP address associated with the web instance."
  value       = aws_eip.web.public_ip
}

output "public_dns" {
  description = "Public DNS name for the Elastic IP."
  value       = aws_eip.web.public_dns
}

output "web_url" {
  description = "HTTP URL for the nginx web server."
  value       = "http://${aws_eip.web.public_ip}"
}

output "ssh_command" {
  description = "Example SSH command when key_name is configured."
  value       = var.key_name == null ? "SSH key not configured" : "ssh -i /path/to/private-key.pem ec2-user@${aws_eip.web.public_ip}"
}
