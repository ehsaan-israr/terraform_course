# Module 09 Solution — Line-by-Line Explanation

This document explains every important line in the Terraform CI/CD pipeline solution.

---

## `terraform/versions.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
```
Pins minimum Terraform version so CI and local runs use compatible syntax (e.g. `check` blocks, optional attributes).

```hcl
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
```
Locks AWS provider to major version 5, preventing breaking provider upgrades in CI.

```hcl
provider "aws" {
  region = var.aws_region
```
All resources deploy to `us-east-1` unless overridden.

```hcl
  default_tags {
    tags = { ... }
```
Automatically tags every AWS resource for cost allocation and ownership tracking.

---

## `terraform/backend.tf`

```hcl
terraform {
  backend "s3" {
    encrypt = true
  }
}
```
Declares **partial** S3 backend configuration. Bucket name, key, region, and DynamoDB table are supplied at `init` time via `backend.hcl` — keeping environment-specific values out of committed code.

---

## `terraform/backend.hcl.example`

Each line maps to an S3 backend argument:

| Line | Purpose |
| --- | --- |
| `bucket` | Globally unique S3 bucket storing `terraform.tfstate` |
| `key` | Path inside bucket for this stack's state file |
| `region` | Region where the bucket lives (`us-east-1`) |
| `dynamodb_table` | Table used for state locking |
| `encrypt` | Server-side encryption for state in transit to S3 |

---

## `terraform/s3-backend.tf`

**`aws_s3_bucket.terraform_state`** — Creates the state bucket. Name comes from `var.state_bucket_name` (must be globally unique).

**`aws_s3_bucket_versioning`** — Enables versioning so you can recover from corrupted or mistaken state writes.

**`aws_s3_bucket_server_side_encryption_configuration`** — Encrypts state at rest with AES256; `bucket_key_enabled` reduces KMS API costs when using KMS keys.

**`aws_s3_bucket_public_access_block`** — Blocks all public access paths — state must never be public.

**`aws_dynamodb_table.terraform_lock`** — Pay-per-request table with hash key `LockID`. Terraform writes lock records here during plan/apply.

---

## `terraform/iam-oidc.tf`

**`data.aws_caller_identity.current`** — Reads current AWS account ID for unique resource naming.

**`aws_iam_openid_connect_provider.github`** — Registers GitHub's OIDC issuer (`token.actions.githubusercontent.com`) so AWS trusts JWTs from GitHub Actions.

**`data.aws_iam_policy_document.github_oidc_assume_role`** — Trust policy with two statements:
1. **Branch access** — `StringLike` on `sub` for `repo:ORG/REPO:ref:refs/heads/main` (and other allowed branches).
2. **PR access** — `repo:ORG/REPO:pull_request` so plan workflows on PRs can assume the role read-only (same role here; split roles in Module 10 for least privilege).

**`aws_iam_role.github_actions_terraform`** — Role GitHub Actions assumes via `configure-aws-credentials`.

**`terraform_state_access` policy** — Minimal S3 list/get/put/delete on state bucket and DynamoDB lock operations.

**`terraform_manage` policy** — Broader infra permissions scoped to `us-east-1` via `aws:RequestedRegion` condition. **Production tip:** replace `resources = ["*"]` with specific ARNs (Module 10).

---

## `terraform/main.tf`

**`aws_s3_bucket.app_artifacts`** — Demo application bucket proving apply creates real resources; name includes account ID for uniqueness.

**`aws_ssm_parameter.cluster_name`** — Stores cluster name for later modules; demonstrates SSM as configuration store.

---

## `terraform/outputs.tf`

Exports values needed for GitHub Secrets setup (`github_actions_role_arn`, `state_bucket_name`, `dynamodb_table_name`) and verification after apply.

---

## `.github/workflows/terraform-plan.yml`

| Section | Explanation |
| --- | --- |
| `on.pull_request.branches: [main]` | Plan only when PRs target main |
| `paths:` | Skip workflow when unrelated files change |
| `permissions.id-token: write` | **Required** for OIDC JWT issuance |
| `permissions.pull-requests: write` | Allows posting plan comments |
| `aws-actions/configure-aws-credentials@v4` | Exchanges OIDC token for temporary AWS credentials |
| `role-to-assume: secrets.AWS_ROLE_ARN` | No static AWS keys in secrets |
| `hashicorp/setup-terraform@v3` | Installs pinned Terraform version |
| `Write backend config` step | Generates `backend.hcl` at runtime from secrets |
| `terraform init -backend-config=backend.hcl` | Connects to remote state |
| `terraform fmt -check` | Fails PR if formatting is inconsistent |
| `terraform plan -out=tfplan` | Saves binary plan for optional apply |
| `upload-artifact` | Preserves plan for audit/debug |
| `github-script` comment | Posts human-readable plan on the PR |

---

## `.github/workflows/terraform-apply.yml`

| Section | Explanation |
| --- | --- |
| `on.push.branches: [main]` | Apply only after merge to main |
| `environment: production` | Optional GitHub Environment with required reviewers (configure in repo settings) |
| `terraform apply -auto-approve` | Non-interactive apply suitable for CI |
| `-var=github_org/repo` | Passes repository identity into Terraform for OIDC trust alignment |

---

## `.github/workflows/terraform-destroy.yml`

| Section | Explanation |
| --- | --- |
| `workflow_dispatch` only | Never auto-destroys on git events |
| `confirm_destroy` input | User must type `destroy` exactly |
| `environment: destroy-approval` | Separate environment for mandatory approvers |
| Validation step | Exits before checkout if confirmation wrong |

---

## Bootstrap Sequence

1. Copy `terraform.tfvars.example` → `terraform.tfvars` and set unique bucket name.
2. **First init without remote backend** (comment out `backend "s3"` block temporarily) OR use `-backend=false`:
   ```bash
   terraform init
   terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_lock
   ```
3. Copy `backend.hcl.example` → `backend.hcl` with real bucket/table names.
4. `terraform init -migrate-state -backend-config=backend.hcl`
5. Add GitHub Secrets and push workflows.

---

## Security Notes

- Never commit `backend.hcl` or `terraform.tfvars` with real account IDs if policy requires secrecy.
- Rotate is unnecessary for OIDC — tokens are short-lived.
- Split **plan role** (read-only) and **apply role** (write) in production (Module 10).
