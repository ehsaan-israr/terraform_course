# App Stack — Remote Backend + Sample S3 Bucket

## Starting point and purpose

This is the **second root** in the Module 4 project. It demonstrates consuming a remote S3 backend created by `bootstrap/` and provisions a small sample S3 artifact bucket. The learning focus is **remote state workflow**, not the bucket itself.

---

## File index

| File | Purpose |
|------|---------|
| `backend.tf` | Partial S3 backend block — bucket, key, region, and lock table supplied at `init`. |
| `versions.tf` | Terraform `>= 1.5.0`, AWS provider. |
| `providers.tf` | AWS provider configuration. |
| `variables.tf` | Region, name prefix, environment, tags. |
| `main.tf` | `aws_s3_bucket.app_artifacts` with encryption, versioning, and public access block. |
| `outputs.tf` | Artifact bucket name and ARN. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Remote state** | `backend.tf` | S3 backend configuration |
| **Artifact storage** | `main.tf` | `aws_s3_bucket.app_artifacts` + hardening |
| **Configuration** | `variables.tf`, `providers.tf` | Inputs and provider setup |

---

## Run

Requires bootstrap outputs first.

```bash
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

---

## State migration practice

To practice migrating from local to remote state:

1. Remove or comment out `backend.tf`.
2. `terraform init` and `terraform apply` (local state).
3. Restore `backend.tf`.
4. `terraform init -migrate-state` with the backend config flags above.

---

## Cleanup

```bash
terraform destroy
```

Destroy this stack **before** destroying the bootstrap backend.
