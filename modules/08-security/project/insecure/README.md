# Insecure Stack — Scan Only, Do Not Apply

## Starting point and purpose

This directory contains **deliberately insecure Terraform** for learning and static analysis. Every pattern here is an anti-pattern you should recognize in code review.

**Never run `terraform apply` in this directory against a real AWS account.**

---

## File index

| File | Purpose |
|------|---------|
| `main.tf` | All insecure resources in one file for easy scanning. |
| `README.md` | This file. |

---

## Feature → file mapping

| Anti-pattern | Location in `main.tf` | Risk |
|-------------|----------------------|------|
| SSH open to `0.0.0.0/0` | `aws_security_group.bad_admin` | Remote compromise |
| S3 without encryption/PAB | `aws_s3_bucket.bad_data` | Data exposure |
| IAM admin `*/*` policy | `aws_iam_policy.bad_admin` | Privilege escalation |
| Hardcoded secret in state | `aws_secretsmanager_secret_version` | Credential leak via state |

---

## Run (scan only)

```bash
checkov -d .
tfsec .
```

Compare findings with `../hardened/` after remediation.
