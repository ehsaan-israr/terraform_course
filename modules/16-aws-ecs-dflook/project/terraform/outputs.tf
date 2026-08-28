output "vpc_id" {
  description = "Lab VPC ID."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB (and by tasks when assign_public_ip is true)."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs for a production-style task placement."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.app.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.app.name
}

output "ecs_execution_role_arn" {
  description = "IAM role used by ECS to pull images and write logs."
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "IAM role assumed by application code inside the container."
  value       = aws_iam_role.ecs_task.arn
}

output "log_group_name" {
  description = "CloudWatch log group for the service."
  value       = aws_cloudwatch_log_group.app.name
}

output "workspace" {
  description = "Terraform workspace used for this plan (dev, staging, or prod)."
  value       = terraform.workspace
}

output "lab_networking_note" {
  description = "Reminder of the lab vs production networking tradeoff for this workspace."
  value       = local.settings.assign_public_ip ? "Workspace ${terraform.workspace}: tasks use public subnets and public IPs (lab shortcut, no NAT)." : "Workspace ${terraform.workspace}: tasks use private subnets. NAT or VPC endpoints are required to pull images."
}
