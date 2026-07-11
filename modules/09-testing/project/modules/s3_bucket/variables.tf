variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must be between 3 and 63 characters."
  }
}

variable "force_destroy" {
  description = "Whether to delete all objects when destroying the bucket. Useful for automated tests."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether S3 bucket versioning is enabled."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ID or ARN. When null, SSE-S3 is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
}

