# Module 4 Project — Remote State with S3 and DynamoDB

## Starting point and purpose

This project teaches the standard **S3 + DynamoDB remote state** pattern used by production Terraform teams. It has **two independent Terraform roots**:

1. **`bootstrap/`** — Creates the state bucket and lock table (uses local state).
2. **`app/`** — A sample application stack that stores its state in the bootstrap backend.

The app stack itself is intentionally minimal (one private S3 artifact bucket). The learning goal is the **backend workflow**, not the application resources.

---

## Architecture

```text
bootstrap/ (local state)
   |
   +-- S3 bucket (versioned, encrypted, private)
   +-- DynamoDB table (state locking)
          |
          v
app/ (remote state in S3)
   |
   +-- S3 artifact bucket (sample application resource)
```

---

## File index

### Project root

| File | Purpose |
|------|---------|
| `README.md` | This file — overall workflow and architecture. |

### `bootstrap/` — Backend infrastructure

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.5.0`; AWS and random providers. |
| `providers.tf` | AWS provider configuration. |
| `variables.tf` | Region, name prefix, environment, force-destroy flag, tags. |
| `main.tf` | S3 state bucket + DynamoDB lock table with hardening. |
| `outputs.tf` | Bucket name, lock table name, region, example `terraform init` command. |
| `README.md` | Bootstrap-specific setup, commands, and cleanup guidance. |

### `app/` — Application stack with remote backend

| File | Purpose |
|------|---------|
| `backend.tf` | Partial S3 backend config (values supplied at `init`). |
| `versions.tf` | Terraform `>= 1.5.0`, AWS provider. |
| `providers.tf` | AWS provider configuration. |
| `variables.tf` | Region, name prefix, environment, tags. |
| `main.tf` | Sample `aws_s3_bucket.app_artifacts` with encryption and versioning. |
| `outputs.tf` | Artifact bucket name and ARN. |
| `README.md` | App-specific init commands and state migration notes. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **State storage (S3)** | `bootstrap/main.tf` | `aws_s3_bucket.terraform_state` + versioning, encryption, PAB |
| **State locking (DynamoDB)** | `bootstrap/main.tf` | `aws_dynamodb_table.terraform_locks` |
| **Unique bucket naming** | `bootstrap/main.tf` | `random_id.suffix`, account ID in bucket name |
| **Remote backend config** | `app/backend.tf` | S3 backend block (partial — values at init) |
| **App artifacts storage** | `app/main.tf` | `aws_s3_bucket.app_artifacts` + hardening |

---

## Run order

### Step 1 — Bootstrap (local state)

```bash
cd bootstrap
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output   # Save state_bucket_name, lock_table_name, backend_region
```

### Step 2 — App (remote state)

```bash
cd ../app
terraform init \
  -backend-config="bucket=<state_bucket_name>" \
  -backend-config="key=state-management/dev/terraform.tfstate" \
  -backend-config="region=<backend_region>" \
  -backend-config="dynamodb_table=<lock_table_name>" \
  -backend-config="encrypt=true"
terraform plan -out=tfplan
terraform apply tfplan
terraform state list
```

### Step 3 — Destroy (reverse order)

```bash
cd ../app && terraform destroy
cd ../bootstrap && terraform apply -var="force_destroy_state_bucket=true"
terraform destroy
```

---

## Optional: local-to-remote migration practice

1. Temporarily remove `app/backend.tf`.
2. Apply locally in `app/`.
3. Restore `backend.tf` and run `terraform init -migrate-state` with backend config.

See `app/README.md` for details.

---

## Troubleshooting

- **Backend bucket not found:** Run bootstrap first and use exact output values in `init -backend-config`.
- **State lock errors:** Ensure no other process holds the DynamoDB lock; check for stale locks.
- **Cannot destroy bootstrap bucket:** Set `force_destroy_state_bucket=true` after destroying the app stack.
