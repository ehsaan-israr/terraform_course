output "ecs_cluster_name" {
  value = aws_ecs_cluster.workloads.name
}

output "application_log_group" {
  value = aws_cloudwatch_log_group.applications.name
}
