# Security Account

## Starting point and purpose

This is the **delegated security services account** root module. It enables organization-wide threat detection, security posture monitoring, and access analysis.

---

## File index

| File | Purpose |
|------|---------|
| `main.tf` | GuardDuty detector, Security Hub account, IAM Access Analyzer. |
| `providers.tf` | Cross-account `assume_role` provider with default tags. |
| `variables.tf` | Account ID, region, role name, name prefix. |
| `versions.tf` | Terraform/AWS provider constraints. |
| `outputs.tf` | GuardDuty detector ID, Access Analyzer ARN. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Threat detection** | `main.tf` | `aws_guardduty_detector.this` |
| **Security posture** | `main.tf` | `aws_securityhub_account.this` |
| **Access analysis** | `main.tf` | `aws_accessanalyzer_analyzer.account` |
| **Cross-account deploy** | `providers.tf` | `assume_role` into security account |

---

## Run

```bash
terraform init
terraform plan \
  -var='account_id=333333333333' \
  -var='name_prefix=acme-security'
```

Apply early in the landing zone rollout — security services should be enabled before workloads.
