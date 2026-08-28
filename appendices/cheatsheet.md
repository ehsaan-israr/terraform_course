# Terraform CLI and HCL Cheatsheet

This cheatsheet is optimized for day-to-day AWS production work. Always read the plan before applying, and never use state commands casually in shared environments.

## Common CLI commands

```bash
terraform fmt -recursive
terraform init
terraform init -upgrade
terraform validate
terraform plan
terraform plan -out=tfplan
terraform show tfplan
terraform show -json tfplan > plan.json
terraform apply tfplan
terraform destroy
terraform providers
terraform version
```

## Safer automation commands

```bash
terraform init -input=false
terraform validate
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
```

## Remote backend init

```bash
terraform init -backend-config=backend.hcl
```

Example `backend.hcl`:

```hcl
bucket         = "example-tfstate-prod"
key            = "production/us-east-1/app/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
```

Reconfigure backend after changing backend settings:

```bash
terraform init -reconfigure
```

Migrate state to a new backend:

```bash
terraform init -migrate-state
```

## State commands

Inspect state:

```bash
terraform state list
terraform state show aws_vpc.main
terraform state pull > state-backup.json
```

Move an address after a refactor:

```bash
terraform state mv aws_instance.web module.compute.aws_instance.web
```

Remove an object from state without destroying the real resource:

```bash
terraform state rm aws_s3_bucket.legacy
```

Replace a provider address in state:

```bash
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws
```

Force unlock only after confirming no run is active:

```bash
terraform force-unlock LOCK_ID
```

Production caution:

- Back up state with `terraform state pull` before state surgery.
- Prefer `moved` blocks for reviewable refactors.
- Do not use `state rm` to hide resources from Terraform without an ownership plan.
- Do not force unlock while an apply may still be running.

## Workspaces

```bash
terraform workspace list
terraform workspace show
terraform workspace new dev
terraform workspace select dev
terraform workspace delete dev
```

Workspace interpolation:

```hcl
locals {
  environment = terraform.workspace
}
```

Workspace guidance:

- Workspaces are state namespaces, not full environment isolation.
- They can work for simple dev/test duplication.
- Many production teams prefer separate root modules and state keys for dev, staging, and production.
- Avoid using workspaces to hide major account or security differences.
- Module 16 uses workspaces (not tfvars) for one ECS root with dflook `workspace:`. One backend key; never apply `default`.

## Import blocks

Terraform 1.5+ import block:

```hcl
import {
  to = aws_s3_bucket.logs
  id = "my-existing-bucket"
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-existing-bucket"
}
```

Workflow:

```bash
terraform plan
terraform apply
terraform plan
```

Legacy import command:

```bash
terraform import aws_s3_bucket.logs my-existing-bucket
```

Import guidance:

- Write configuration before importing.
- Import one logical resource at a time.
- After import, run a plan and reconcile differences.
- Remove import blocks after the import is complete if your team prefers one-time import declarations.

## Moved blocks

Resource moved into a module:

```hcl
moved {
  from = aws_instance.web
  to   = module.compute.aws_instance.web
}
```

Resource key changed:

```hcl
moved {
  from = aws_security_group_rule.ingress[0]
  to   = aws_security_group_rule.ingress["https"]
}
```

Moved block guidance:

- Use moved blocks for code-reviewed refactors.
- Keep them long enough for all active branches to pass through the migration.
- Do not combine large refactors with unrelated infrastructure changes.

## Provider pinning

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Provider aliases:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "networking"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::222233334444:role/terraform-execution"
  }
}
```

Pass aliases to modules:

```hcl
module "attachment" {
  source = "./modules/tgw-attachment"

  providers = {
    aws.networking = aws.networking
    aws.workload   = aws
  }
}
```

## Useful HCL functions

String and collection helpers:

```hcl
lower("Prod")                         # "prod"
replace("prod_us_east_1", "_", "-")   # "prod-us-east-1"
contains(["dev", "prod"], var.env)    # true/false
lookup(var.tags, "Owner", "unknown")  # safe map lookup
coalesce(var.name, "default")         # first non-null value
try(var.config.name, "default")       # fallback if expression errors
can(regex("^prod", var.env))          # true if expression succeeds
```

Network helpers:

```hcl
cidrsubnet("10.0.0.0/16", 8, 10)
cidrhost("10.0.1.0/24", 10)
```

Encoding helpers:

```hcl
jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect   = "Allow"
    Action   = ["s3:GetObject"]
    Resource = ["arn:aws:s3:::example/*"]
  }]
})

yamldecode(file("${path.module}/config.yml"))
```

Collection transforms:

```hcl
locals {
  azs = ["us-east-1a", "us-east-1b"]

  subnet_map = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, idx)
  }

  required_tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}
```

## Useful HCL patterns

Stable `for_each`:

```hcl
resource "aws_subnet" "private" {
  for_each = local.subnet_map

  availability_zone = each.key
  cidr_block        = each.value
  vpc_id            = aws_vpc.main.id
}
```

Variable validation:

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}
```

Lifecycle protection:

```hcl
resource "aws_db_instance" "prod" {
  # ...

  deletion_protection = true

  lifecycle {
    prevent_destroy = true
  }
}
```

Precondition:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name

  lifecycle {
    precondition {
      condition     = startswith(var.bucket_name, "logs-")
      error_message = "Log bucket names must start with logs-."
    }
  }
}
```

## Plan review checklist

- Are there unexpected destroys or replacements?
- Did provider versions change?
- Did state addresses move intentionally?
- Are sensitive values hidden?
- Are public network paths intentional?
- Are IAM permissions broader than before?
- Are RDS, Redis, S3, and EBS resources encrypted?
- Are backups and deletion protection preserved?
- Did the change alter DNS, CloudFront, WAF, or routing?
- Is cost impact understood?
- Are production changes approved by the right owners?
