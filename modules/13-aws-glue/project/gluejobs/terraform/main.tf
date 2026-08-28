locals {
  job_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_glue_job" "this" {
  for_each = var.glue_jobs

  name        = "${var.environment}-${each.value.name}"
  description = lookup(each.value, "description", "")
  role_arn    = var.glue_role_arn

  glue_version      = lookup(each.value, "glue_version", "4.0")
  worker_type       = lookup(each.value, "worker_type", "G.1X")
  number_of_workers = lookup(each.value, "number_of_workers", 2)
  timeout           = lookup(each.value, "timeout", 60)
  max_retries       = lookup(each.value, "max_retries", 0)
  max_capacity      = lookup(each.value, "max_capacity", null)

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_s3_bucket}/${var.scripts_s3_prefix}/${each.value.job_folder}/${lookup(each.value, "script", "scripts/main.py")}"
    python_version  = "3"
  }

  default_arguments = merge(
    lookup(each.value, "arguments", {}),
    {
      "--job-language" = "python"
      "--JOB_NAME"     = "${var.environment}-${each.value.name}"
    }
  )

  tags = merge(local.job_tags, {
    Job = each.value.name
  })
}
