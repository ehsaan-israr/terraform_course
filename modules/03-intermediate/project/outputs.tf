output "account_id" {
  description = "AWS account ID read through a data source."
  value       = data.aws_caller_identity.current.account_id
}

output "ami_id" {
  description = "AMI ID selected for all servers."
  value       = data.aws_ami.amazon_linux_2023.id
}

output "server_ids" {
  description = "EC2 instance IDs keyed by server name."
  value = {
    for name, instance in aws_instance.server :
    name => instance.id
  }
}

output "server_private_ips" {
  description = "Private IPs keyed by server name."
  value = {
    for name, instance in aws_instance.server :
    name => instance.private_ip
  }
}

output "server_public_ips" {
  description = "Public IPs keyed by server name. Uses Elastic IPs when create_elastic_ips is true; otherwise uses instance public IPs."
  value = var.create_elastic_ips ? {
    for name, eip in aws_eip.server :
    name => eip.public_ip
    } : {
    for name, instance in aws_instance.server :
    name => instance.public_ip
  }
}

output "web_urls" {
  description = "HTTP URLs for servers with public IPs."
  value = var.create_elastic_ips ? {
    for name, eip in aws_eip.server :
    name => "http://${eip.public_ip}"
    } : {
    for name, instance in aws_instance.server :
    name => "http://${instance.public_ip}"
  }
}

output "admin_password" {
  description = "Demo sensitive output. This is hidden in normal CLI output but can still exist in state."
  value       = var.admin_password
  sensitive   = true
}
