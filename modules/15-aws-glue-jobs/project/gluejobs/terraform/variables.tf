variable "environment" {
  description = "Deployment stage (dev, qa, uat, prod). Set via GitHub vars.env in CI."
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "glue_role_arn" {
  description = "IAM role ARN used by Glue jobs in this environment"
  type        = string
}

variable "scripts_s3_bucket" {
  description = "S3 bucket where Glue scripts are stored"
  type        = string
}

variable "scripts_s3_prefix" {
  description = "S3 prefix for Glue scripts"
  type        = string
  default     = "glue-jobs"
}

variable "glue_jobs" {
  description = "Glue job definitions generated from gluejobs/*/job.yaml"
  type = map(object({
    name              = string
    description       = optional(string, "")
    glue_version      = optional(string, "4.0")
    worker_type       = optional(string, "G.1X")
    number_of_workers = optional(number, 2)
    timeout           = optional(number, 60)
    max_retries       = optional(number, 0)
    max_capacity      = optional(number)
    script            = optional(string, "scripts/main.py")
    job_folder        = string
    arguments         = optional(map(string), {})
  }))
}
