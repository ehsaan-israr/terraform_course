output "cluster_id" {
  description = "ECS cluster ID."
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "Task definition ARN for the sample service."
  value       = aws_ecs_task_definition.this.arn
}

output "task_execution_role_arn" {
  description = "IAM role ARN used by ECS to pull images and write logs."
  value       = aws_iam_role.task_execution.arn
}

output "service_name" {
  description = "ECS service name when create_service is true."
  value       = var.create_service ? aws_ecs_service.this[0].name : null
}

