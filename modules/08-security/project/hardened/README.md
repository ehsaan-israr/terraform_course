# Hardened Stack — Remediated Security Patterns

## Starting point and purpose

This directory contains the **remediated version** of the insecure stack from `../insecure/`. Each anti-pattern has been replaced with a production-appropriate alternative.

Safe to apply in a **sandbox account** with real variable values.

---

## File index

| File | Purpose |
|------|---------|
| `main.tf` | Restricted SG, encrypted S3, least-privilege IAM, Secrets Manager data source. |
| `variables.tf` | Region, VPC ID, admin CIDRs, secret name, bucket name. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Secret lookup (no hardcoding)** | `main.tf` | `data.aws_secretsmanager_secret.db` |
| **Restricted SSH access** | `main.tf`, `variables.tf` | `aws_security_group.admin` with `var.admin_cidrs` |
| **S3 hardening** | `main.tf` | PAB, SSE, versioning on `aws_s3_bucket.data` |
| **Least-privilege IAM** | `main.tf` | `aws_iam_policy.app` scoped to secret + bucket |

---

## Run

```bash
terraform init
terraform validate
terraform plan \
  -var='vpc_id=vpc-0123456789abcdef0' \
  -var='admin_cidrs=["203.0.113.10/32"]'
# terraform apply   # sandbox only
```

Replace `vpc_id` and `admin_cidrs` with real values from your lab account.
