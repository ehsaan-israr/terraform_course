# Module 02 Exercise: Terraform S3 Storage Project

## Objective

Build a Terraform project from scratch that creates an AWS S3 bucket with versioning enabled, using variables, outputs, a child module, and workspaces—without referencing the solution until finished.

---

## Requirements

1. Terraform >= 1.5 with AWS provider `~> 5.0`.
2. S3 bucket with versioning **Enabled**.
3. All resources tagged with `Environment`, `Project`, and `ManagedBy`.
4. A reusable `modules/storage` child module with clear variable and output interfaces.
5. Root-level `variables.tf`, `outputs.tf`, `versions.tf`, and `main.tf`.
6. `terraform.tfvars.example` documenting required variables.
7. `backend.tf.example` showing S3 backend configuration (do not require a live backend for the exercise).
8. `.gitignore` excluding state files and secrets.

---

## Constraints

- Bucket names must be globally unique; use a naming convention that avoids collisions.
- Do not store secrets in `terraform.tfvars` or commit state files.
- Use `us-east-1` unless you document another region.
- Variable validations must reject empty `project_name` and invalid `environment` values.
- Do not enable public access on the bucket.

---

## Tasks

### Task 1: Project Scaffold

Create the folder structure:

```text
your-terraform-project/
├── versions.tf
├── variables.tf
├── outputs.tf
├── main.tf
├── terraform.tfvars.example
├── backend.tf.example
├── .gitignore
└── modules/storage/
    ├── versions.tf
    ├── variables.tf
    ├── main.tf
    └── outputs.tf
```

### Task 2: Storage Module

Inside `modules/storage`, implement:

1. `aws_s3_bucket` with force destroy enabled (for easy cleanup in learning).
2. `aws_s3_bucket_versioning` with status `Enabled`.
3. `aws_s3_bucket_public_access_block` blocking all public access.
4. Standard tags on all resources.

Module outputs: `bucket_id`, `bucket_arn`, `versioning_status`.

### Task 3: Root Module

Wire the storage module from the root. Pass variables through. Export root outputs for bucket ID, ARN, region, and versioning status.

### Task 4: Variables and Validation

Define at minimum:

| Variable | Type | Validation |
| --- | --- | --- |
| `project_name` | string | non-empty |
| `environment` | string | one of: dev, staging, prod |
| `aws_region` | string | non-empty |
| `common_tags` | map(string) | optional, merged with required tags |

### Task 5: Backend Example

Create `backend.tf.example` with commented instructions for S3 backend. Include `bucket`, `key`, `region`, and placeholder for DynamoDB table (used in Module 09).

### Task 6: Workspaces

1. Create workspaces `dev` and `staging`.
2. Apply in each with appropriate `environment` variable.
3. Verify separate state files exist under `.terraform/`.

### Task 7: Validation

Run `terraform fmt -recursive`, `terraform validate`, `terraform plan`, and `terraform apply`.

---

## Expected Deliverables

| Deliverable | Description |
| --- | --- |
| Complete Terraform project | All `.tf` files and examples |
| Applied infrastructure | S3 bucket visible in AWS Console |
| Workspace list | Output of `terraform workspace list` |
| Plan output | Saved `plan.out` or screenshot showing 0 changes post-apply |

---

## Validation Checklist

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` succeeds
- [ ] `terraform plan` shows only intended resources
- [ ] S3 bucket exists with correct name pattern
- [ ] Versioning is Enabled (verify via AWS CLI or Console)
- [ ] Public access is blocked on the bucket
- [ ] Tags `Environment`, `Project`, `ManagedBy` present on bucket
- [ ] Root outputs return `bucket_id`, `bucket_arn`, `versioning_status`
- [ ] `modules/storage` has no hard-coded environment values
- [ ] `terraform.tfvars` is in `.gitignore`
- [ ] `terraform.tfstate` is in `.gitignore`
- [ ] `backend.tf.example` exists with S3 backend block
- [ ] Workspaces `dev` and `staging` created and tested
- [ ] `terraform destroy` successfully removes all resources (test cleanup)

---

**When finished:** Compare with `solution/` and read `SOLUTION.md` for detailed explanations.
