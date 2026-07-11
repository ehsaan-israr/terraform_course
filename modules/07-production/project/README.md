# Module 7 Project — Production Terraform Repository Layout

## Starting point and purpose

This project models how **production teams organize Terraform**: reusable modules, separate `live/` roots per environment, remote S3 backends, cross-account role assumption, and GitHub Actions CI (plan on PR, apply on merge to `main`).

The fictional app is **acme-payments** — a VPC + app security group + artifact S3 bucket per environment, with blue/green tagging via `active_color`. Placeholders stand in for real account IDs, role ARNs, and state bucket names.

**Learning goals:** multi-environment repo layout, remote state per env, `assume_role` providers, module reuse, and CI/CD integration.

---

## Architecture

```text
.github/workflows/terraform.yml
   |
   +-- live/dev/     --> modules/networking + modules/app
   +-- live/staging/ --> modules/networking + modules/app
   +-- live/prod/    --> modules/networking + modules/app
```

Each `live/*` root has its own S3 backend and assumes a role into a target AWS account.

---

## File index

### Project root

| File | Purpose |
|------|---------|
| `README.md` | This file — layout, environment table, run commands. |
| `.gitignore` | Ignores `.terraform/`, state files, plans, lock file, overrides. |

### CI/CD

| File | Purpose |
|------|---------|
| `.github/workflows/terraform.yml` | Matrix CI: plan on PR, apply on push to `main` for dev/staging/prod. |

### `live/dev/`, `live/staging/`, `live/prod/` (one set per environment)

| File | Purpose |
|------|---------|
| `main.tf` | Composes `networking` + `app` modules with environment-specific CIDRs and tags. |
| `backend.tf` | S3 backend + Terraform/provider version constraints. |
| `providers.tf` | AWS provider with `assume_role` and default tags. |
| `variables.tf` | `aws_region`, `active_color`. |

### `modules/networking/`

| File | Purpose |
|------|---------|
| `main.tf` | VPC, IGW, public subnets, route table, associations. |
| `variables.tf` | CIDR, AZs, name prefix, tags. |
| `outputs.tf` | `vpc_id`, `public_subnet_ids`. |

### `modules/app/`

| File | Purpose |
|------|---------|
| `main.tf` | Web security group, S3 artifacts bucket + encryption/versioning/PAB. |
| `variables.tf` | VPC ID, HTTP CIDRs, blue/green color, environment. |
| `outputs.tf` | Security group ID, bucket name. |

---

## Feature → file mapping

| Feature | Contributing files |
|---------|-------------------|
| **Multi-environment layout** | `live/dev/`, `live/staging/`, `live/prod/` |
| **Remote state (S3 + DynamoDB lock)** | Each `live/*/backend.tf` |
| **Cross-account deployment** | Each `live/*/providers.tf` (`assume_role`) |
| **VPC networking** | `modules/networking/*`, called from each `live/*/main.tf` |
| **App security group (HTTP ingress)** | `modules/app/main.tf`, wired via `vpc_id` |
| **Artifact S3 bucket** | `modules/app/main.tf` (encrypted, no public access) |
| **Blue/green deployment tagging** | `modules/app/variables.tf` (`active_color`), `live/*/variables.tf` |
| **Environment-specific sizing** | Different CIDRs/AZ counts in each `live/*/main.tf` |
| **Prod-only S3 versioning** | `modules/app/main.tf` (`environment == "prod"`) |
| **CI/CD (plan/apply matrix)** | `.github/workflows/terraform.yml` |
| **Consistent tagging** | `locals.common_tags` in each `live/*/main.tf`, provider `default_tags` |

### Environment differences

| Env | VPC CIDR | AZs | S3 versioning |
|-----|----------|-----|---------------|
| dev | `10.10.0.0/16` | 2 | Suspended |
| staging | `10.20.0.0/16` | 2 | Suspended |
| prod | `10.30.0.0/16` | 3 | Enabled |

---

## Prerequisites

- S3 state buckets + DynamoDB lock tables per environment.
- Replace placeholder account IDs and role ARNs in `providers.tf`.
- Replace bucket names in `backend.tf`.
- Configure GitHub OIDC for CI (optional).

---

## Run

```bash
cd live/dev
terraform init
terraform fmt -recursive ../..
terraform validate
terraform plan
# terraform apply   # after review
```

Repeat from `live/staging` or `live/prod`. CI runs automatically on PR/push when `live/**` or `modules/**` change.

---

## Key resources (per environment)

- `aws_vpc`, `aws_internet_gateway`, `aws_subnet`, `aws_route_table`, `aws_route_table_association`
- `aws_security_group` (web — HTTP in, HTTPS out)
- `aws_s3_bucket`, `aws_s3_bucket_public_access_block`, `aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_versioning`
