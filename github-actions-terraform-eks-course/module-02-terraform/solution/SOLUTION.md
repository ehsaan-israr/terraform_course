# Module 02 Solution: Terraform S3 Storage

Line-by-line explanation of the reference implementation.

---

## Root `versions.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
```

Enforces Terraform 1.5+ for `check` blocks and other features used later in the course.

```hcl
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
```

`~> 5.0` allows 5.x patches/minors but blocks 6.0 breaking upgrades.

---

## Root `variables.tf`

```hcl
variable "project_name" {
  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}
```

`trimspace` rejects whitespace-only names that would produce invalid bucket names.

```hcl
variable "environment" {
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}
```

Fails at `terraform plan` before any AWS API call—cheap feedback.

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  default_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
  tags = merge(local.default_tags, var.common_tags)
}
```

Centralizes tagging logic; `merge` lets callers add extra tags without overriding required ones.

---

## Root `main.tf`

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
```

Provider `default_tags` (AWS provider 3.38+) automatically applies tags to supported resources—reduces repetition. Module still sets tags explicitly for clarity.

```hcl
module "storage" {
  source = "./modules/storage"

  bucket_name = "${local.name_prefix}-storage-${var.bucket_suffix}"
  tags        = local.tags
}
```

`bucket_suffix` adds uniqueness (e.g., account ID fragment) to avoid global name collisions.

---

## `modules/storage/main.tf`

```hcl
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}
```

`force_destroy = true` allows `terraform destroy` to delete non-empty buckets—acceptable for learning, **not** for production state buckets.

```hcl
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

Versioning is a separate resource in AWS provider 4.x+ (split from monolithic bucket resource).

```hcl
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

Defense-in-depth: bucket cannot become public accidentally.

---

## `backend.tf.example`

```hcl
# terraform {
#   backend "s3" {
#     bucket         = "mycompany-terraform-state"
#     key            = "module-02/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }
```

Commented so learners use local state first. `encrypt = true` enables SSE-S3 for state at rest. DynamoDB table added in Module 09 for locking.

---

## Workspaces

```bash
terraform workspace new dev
terraform apply -var-file=terraform.tfvars
```

Each workspace stores state at `terraform.tfstate.d/<workspace>/terraform.tfstate` locally, or a different `key` prefix when using S3 backend.

---

## Apply and Destroy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
```

Always run `plan` before `apply` in CI/CD (Module 09).
