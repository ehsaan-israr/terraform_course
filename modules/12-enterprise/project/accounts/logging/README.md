# Logging Account

## Starting point and purpose

This is the **central log archive account** root module. It stores immutable audit logs and organization-wide CloudTrail events.

---

## File index

| File | Purpose |
|------|---------|
| `main.tf` | Log archive S3 bucket, organization CloudTrail. |
| `providers.tf` | Cross-account `assume_role` provider with default tags. |
| `variables.tf` | Account ID, region, role name, name prefix. |
| `versions.tf` | Terraform/AWS provider constraints. |
| `outputs.tf` | Log bucket name, CloudTrail ARN. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Immutable log archive** | `main.tf` | S3 bucket + encryption + PAB + versioning |
| **Organization audit trail** | `main.tf` | `aws_cloudtrail.organization` |
| **Cross-account deploy** | `providers.tf` | `assume_role` into logging account |

---

## Run

```bash
terraform init
terraform plan \
  -var='account_id=444444444444' \
  -var='name_prefix=acme-logging'
```

Apply first or alongside the security account — audit logging should be in place before workloads.
