# Networking Account

## Starting point and purpose

This is the **central network account** root module. It provisions shared networking primitives that other accounts attach to: a shared VPC, a Transit Gateway, and VPC Flow Logs.

Each account folder is an independent Terraform root with its own state file and `assume_role` provider.

---

## File index

| File | Purpose |
|------|---------|
| `main.tf` | Shared VPC, Transit Gateway, VPC flow logs, CloudWatch log group. |
| `providers.tf` | Cross-account `assume_role` provider with default tags. |
| `variables.tf` | Account ID, region, role name, name prefix. |
| `versions.tf` | Terraform/AWS provider constraints. |
| `outputs.tf` | VPC ID, Transit Gateway ID for cross-account consumption. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Shared VPC** | `main.tf` | `aws_vpc.shared` (`10.100.0.0/16`) |
| **Transit Gateway** | `main.tf` | `aws_ec2_transit_gateway.this` |
| **VPC flow logs** | `main.tf` | `aws_flow_log.vpc`, `aws_cloudwatch_log_group.flow_logs` |
| **Cross-account deploy** | `providers.tf` | `assume_role` into networking account |

---

## Run

```bash
terraform init
terraform plan \
  -var='account_id=111111111111' \
  -var='name_prefix=acme-networking'
```

Apply networking before workload accounts that depend on shared network outputs.

---

## Operating guidance

- Keep this root small — only network-account resources belong here.
- Require pull request review for all changes.
- Publish VPC/TGW IDs via remote state or SSM for workload accounts.
