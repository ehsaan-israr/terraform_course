# Production Workload Account

## Starting point and purpose

This is the **customer-facing production workload account** root module. It mirrors staging but with stricter safety settings: longer log retention, longer backup retention, and RDS deletion protection enabled.

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
| **Application logging** | `main.tf` | `aws_cloudwatch_log_group.applications` (14-day retention) |
| **Database (protected)** | `main.tf`, `workload_variables.tf` | `aws_db_instance` (14-day backups, `deletion_protection = true`) |
| **Cross-account deploy** | `providers.tf` | `assume_role` into production account |

### Staging vs production differences

| Setting | Staging | Production |
|---------|---------|------------|
| Log retention | 7 days | 14 days |
| Backup retention | 7 days | 14 days |
| Deletion protection | `false` | `true` |

---

## Run

```bash
terraform init
terraform plan \
  -var='account_id=666666666666' \
  -var='name_prefix=acme-prod' \
  -var='database_subnet_ids=["subnet-abc","subnet-def"]' \
  -var='database_password=...'
```

Apply after staging is validated and networking/shared-services are in place.
