# Module 12 Project — Multi-Account AWS Landing Zone

## Starting point and purpose

This project is a **multi-account AWS landing zone teaching scaffold**. Each folder under `accounts/` is an independent Terraform root module that assumes a role into one AWS account.

It demonstrates account-aligned Terraform: networking, shared services, security, logging, staging, and production — with cross-account provider patterns and one-state-file-per-account guidance.

See `ARCHITECTURE.md` for the full account layout and remote state recommendations.

**Learning goals:** multi-account strategy, `assume_role` providers, account-per-root-module, and landing zone resource placement.

---

## Architecture

```text
accounts/
  networking/       --> Shared VPC, Transit Gateway, flow logs
  shared-services/  --> ECR, artifacts S3, SSM parameters
  security/         --> GuardDuty, Security Hub, Access Analyzer
  logging/          --> Log archive S3, organization CloudTrail
  staging/          --> ECS cluster, RDS (relaxed settings)
  production/       --> ECS cluster, RDS (deletion protection)
```

Each account root assumes `TerraformExecutionRole` via `providers.tf`.

---

## File index

### Project root

| File | Purpose |
|------|---------|
| `ARCHITECTURE.md` | Account layout, provider model, remote state key patterns. |
| `README.md` | This file. |

### Per-account standard files (`accounts/<name>/`)

| File | Purpose |
|------|---------|
| `main.tf` | Account-specific resources. |
| `providers.tf` | Cross-account `assume_role` provider with default tags. |
| `variables.tf` | Account ID, region, role name, name prefix. |
| `versions.tf` | Terraform/AWS provider constraints. |
| `outputs.tf` | Values for cross-account consumption. |
| `README.md` | Account purpose and operating guidance. |
| `workload_variables.tf` | *(staging/production only)* DB subnet IDs, instance class, credentials. |

---

## Feature → file mapping (by account)

| Account | Feature | Key files | Key resources |
|---------|---------|-----------|---------------|
| **networking** | Shared VPC | `accounts/networking/main.tf` | `aws_vpc.shared` |
| | Transit Gateway | `accounts/networking/main.tf` | `aws_ec2_transit_gateway.this` |
| | VPC flow logs | `accounts/networking/main.tf` | `aws_flow_log.vpc`, `aws_cloudwatch_log_group.flow_logs` |
| **shared-services** | Container registry | `accounts/shared-services/main.tf` | `aws_ecr_repository.platform` |
| | Artifact storage | `accounts/shared-services/main.tf` | `aws_s3_bucket.artifacts` + versioning |
| | Cross-stack parameter | `accounts/shared-services/main.tf` | `aws_ssm_parameter.artifact_bucket` |
| **security** | Threat detection | `accounts/security/main.tf` | `aws_guardduty_detector.this` |
| | Security posture | `accounts/security/main.tf` | `aws_securityhub_account.this` |
| | Access analysis | `accounts/security/main.tf` | `aws_accessanalyzer_analyzer.account` |
| **logging** | Log archive | `accounts/logging/main.tf` | S3 + encryption + PAB + versioning |
| | Audit trail | `accounts/logging/main.tf` | `aws_cloudtrail.organization` |
| **staging** | Container platform | `accounts/staging/main.tf` | `aws_ecs_cluster.workloads` |
| | App logging | `accounts/staging/main.tf` | `aws_cloudwatch_log_group.applications` (7-day retention) |
| | Database | `accounts/staging/main.tf`, `workload_variables.tf` | `aws_db_instance` (no deletion protection) |
| **production** | Same as staging, stricter | `accounts/production/main.tf` | 14-day logs/backups, `deletion_protection = true` |
| **All accounts** | Cross-account deploy | Each `providers.tf` | `assume_role` into target account |

---

## Prerequisites

- Six AWS accounts (or sandbox equivalents).
- `TerraformExecutionRole` in each account.
- Replace placeholder `account_id` and `name_prefix` values.
- Add S3 backends per account (see `ARCHITECTURE.md`).

---

## Run order

Apply in practice: logging + security first, then networking, shared-services, then staging/production.

```bash
cd accounts/networking
terraform init
terraform plan \
  -var='account_id=111111111111' \
  -var='name_prefix=acme-networking'
```

Workload accounts also need DB inputs:

```bash
cd accounts/production
terraform plan \
  -var='account_id=222222222222' \
  -var='name_prefix=acme-prod' \
  -var='database_subnet_ids=["subnet-abc","subnet-def"]' \
  -var='database_password=...'
```

See each account's `README.md` for account-specific details.
