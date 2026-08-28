output "glue_job_names" {
  description = "Deployed Glue job names"
  value       = { for key, job in aws_glue_job.this : key => job.name }
}

output "glue_job_arns" {
  description = "Deployed Glue job ARNs"
  value       = { for key, job in aws_glue_job.this : key => job.arn }
}
