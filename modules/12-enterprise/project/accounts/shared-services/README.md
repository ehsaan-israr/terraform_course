# Shared Services Account

## Starting point and purpose

This is the **shared platform services account** root module. It hosts resources used across the organization: container registry, artifact storage, and cross-stack parameters.

---

## File index

| File | Purpose |
|------|---------|
| `main.tf` | ECR repository, artifacts S3 bucket, SSM parameter. |
| `providers.tf` | Cross-account `assume_role` provider with default tags. |
| `variables.tf` | Account ID, region, role name, name prefix. |
| `versions.tf` | Terraform/AWS provider constraints. |
| `outputs.tf` | ECR URL, artifact bucket name. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Container registry** | `main.tf` | `aws_ecr_repository.platform` |
| **Artifact storage** | `main.tf` | `aws_s3_bucket.artifacts` + versioning |
| **Cross-stack parameter** | `main.tf` | `aws_ssm_parameter.artifact_bucket` |
| **Cross-account deploy** | `providers.tf` | `assume_role` into shared-services account |

---

## Run

```bash
terraform init
terraform plan \
  -var='account_id=222222222222' \
  -var='name_prefix=acme-shared'
```

Apply after logging/security foundations; before workload accounts that pull images or artifacts.
