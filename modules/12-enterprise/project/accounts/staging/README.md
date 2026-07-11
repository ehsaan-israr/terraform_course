# Staging Workload Account

## Starting point and purpose

This is the **pre-production workload account** root module. It provisions an ECS cluster, application logging, and a placeholder RDS instance with relaxed safety settings suitable for testing.

---

## File index

| File | Purpose |
|------|---------|
| `main.tf` | ECS cluster, CloudWatch log group, DB subnet group, RDS instance. |
| `providers.tf` | Cross-account `assume_role` provider with default tags. |
| `variables.tf` | Account ID, region, role name, name prefix. |
| `workload_variables.tf` | DB subnet IDs, instance class, username, password. |
| `versions.tf` | Terraform/AWS provider constraints. |
| `outputs.tf` | ECS cluster name, log group name. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Container platform** | `main.tf` | `aws_ecs_cluster.workloads` (Container Insights on) |
| **Application logging** | `main.tf` | `aws_cloudwatch_log_group.applications` (7-day retention) |
| **Database** | `main.tf`, `workload_variables.tf` | `aws_db_subnet_group`, `aws_db_instance` (no deletion protection) |
| **Cross-account deploy** | `providers.tf` | `assume_role` into staging account |

---

## Run

```bash
terraform init
terraform plan \
  -var='account_id=555555555555' \
  -var='name_prefix=acme-staging' \
  -var='database_subnet_ids=["subnet-abc","subnet-def"]' \
  -var='database_password=...'
```

Apply after networking and shared-services foundations are in place.
