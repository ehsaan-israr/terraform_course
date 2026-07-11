# Module 8 Project — Security Remediation Lab

## Starting point and purpose

This project compares **intentionally insecure Terraform** (`insecure/`) with a **hardened version** (`hardened/`). Use it for manual code review, Checkov/tfsec scanning, and understanding business risk versus technical fixes.

**Do not apply `insecure/` to a real AWS account.**

**Learning goals:** identify common Terraform security anti-patterns, remediate them, and integrate static security scanning into your workflow.

---

## Architecture

```text
project/
  insecure/     --> Deliberately bad patterns (scan only)
  hardened/     --> Remediated patterns (safe to apply in sandbox)
  .checkov.yaml --> Scanner configuration
```

---

## File index

### Project root

| File | Purpose |
|------|---------|
| `README.md` | This file — lab structure, remediation checklist, scanner commands. |
| `.checkov.yaml` | Checkov config (terraform framework, compact output). |

### `insecure/` — Deliberately bad patterns

| File | Purpose |
|------|---------|
| `main.tf` | Insecure SG (SSH open to internet), bare S3, admin IAM policy, hardcoded Secrets Manager password. |
| `README.md` | Warning: do not apply; scan-only guidance. |

### `hardened/` — Remediated patterns

| File | Purpose |
|------|---------|
| `main.tf` | Restricted SG, encrypted/versioned S3, least-privilege IAM, secret lookup via data source. |
| `variables.tf` | Region, VPC ID, admin CIDRs, secret name, bucket name. |
| `README.md` | Hardening summary and example plan commands. |

---

## Feature → file mapping

| Feature | Insecure files | Hardened files |
|---------|---------------|----------------|
| **Secret exposure** | `insecure/main.tf` (hardcoded password in state) | `hardened/main.tf` (`data.aws_secretsmanager_secret`) |
| **Network exposure** | `insecure/main.tf` (SSH `0.0.0.0/0`) | `hardened/main.tf` (`var.admin_cidrs`) |
| **S3 data protection** | `insecure/main.tf` (bare bucket) | `hardened/main.tf` (PAB, encryption, versioning) |
| **IAM least privilege** | `insecure/main.tf` (`*/*` admin policy) | `hardened/main.tf` (scoped secret + bucket actions) |
| **Static security scanning** | `.checkov.yaml`, README scanner commands | Same |

### Key resources

**insecure/ (intentionally bad):**

- `aws_security_group.bad_admin` — SSH open to internet
- `aws_s3_bucket.bad_data` — no encryption or public access block
- `aws_iam_policy.bad_admin` — full admin access
- `aws_secretsmanager_secret` + version — password stored in Terraform state

**hardened/:**

- `data.aws_secretsmanager_secret.db`
- `aws_security_group.admin` — SSH from approved CIDRs only
- `aws_s3_bucket.data` + PAB + SSE + versioning
- `aws_iam_policy.app` — read secret, read/write specific bucket

---

## Run

### Scan only (recommended for insecure)

```bash
checkov -d insecure
tfsec insecure
checkov -d hardened
tfsec hardened
```

### Apply hardened (sandbox only)

```bash
cd hardened
terraform init
terraform validate
terraform plan \
  -var='vpc_id=vpc-0123456789abcdef0' \
  -var='admin_cidrs=["203.0.113.10/32"]'
```

---

## Student tasks

1. Run Checkov on both directories and compare finding counts.
2. For each insecure finding, identify the business risk and the hardened fix.
3. Add a `tfsec` or `checkov` step to a GitHub Actions workflow.
