# Module 6 Project — Production-Style AWS Platform Skeleton

## Starting point and purpose

This project assembles a **cohesive production-style platform** in a single root module, split by concern (one file per domain rather than child modules). It demonstrates how real teams organize large Terraform roots before extracting modules.

**What you build:**

- VPC with public/private subnets and optional NAT gateway.
- Tiered security groups and IAM roles for ECS.
- Application Load Balancer → ECS Fargate service.
- Private RDS PostgreSQL and encrypted S3 bucket.
- CloudWatch log group and metric alarms.

**Learning goals:** file-per-concern layout, ALB→ECS→RDS traffic flow, IAM task roles, and production monitoring primitives.

---

## Architecture

```text
Internet
   |
ALB (public subnets)
   |
ECS Fargate tasks (private subnets)
   |
   +-- RDS PostgreSQL (private, port 5432)
   +-- S3 (via task IAM role)
```

---

## File index

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.5.0`; AWS and random providers. |
| `providers.tf` | AWS provider configuration. |
| `variables.tf` | VPC CIDRs, subnets, NAT flag, app port, container image, ECS count, DB settings. |
| `network.tf` | Locals, VPC, subnets, IGW, route tables, optional NAT gateway. |
| `security.tf` | ALB/app/database security groups; ECS execution + task IAM roles; S3 access policy. |
| `compute.tf` | ALB, target group, listener, ECS cluster, task definition, service. |
| `database.tf` | Random DB password, subnet group, RDS PostgreSQL instance. |
| `storage.tf` | Private encrypted versioned S3 bucket with lifecycle rule. |
| `monitoring.tf` | CloudWatch log group, ALB 5xx alarm, ECS CPU alarm. |
| `outputs.tf` | VPC/subnet IDs, ALB DNS, ECS names, bucket, DB endpoint, password warning. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Networking** | `network.tf` | VPC, subnets, IGW, route tables, optional NAT |
| **Security / IAM** | `security.tf` | Security groups, ECS execution/task roles, S3 policy |
| **Compute (ALB + ECS)** | `compute.tf` | ALB, target group, listener, ECS cluster/service/task |
| **Database** | `database.tf` | RDS PostgreSQL, DB subnet group |
| **Storage** | `storage.tf` | S3 bucket with encryption, versioning, lifecycle |
| **Monitoring** | `monitoring.tf`, `compute.tf` | Log group, ALB 5xx alarm, ECS CPU alarm |
| **Configuration** | `variables.tf`, `network.tf` (locals) | Inputs and shared locals |

**Traffic path:** Internet → ALB (public) → ECS tasks (private) → RDS (5432) / S3 (task role)

---

## Run

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply    # Review cost: ALB, Fargate, RDS; NAT if enabled
terraform output alb_dns_name
terraform destroy
```

Default `enable_nat_gateway = false`. ECS tasks in private subnets need NAT or VPC endpoints to pull images and write logs. Set `enable_nat_gateway = true` for working egress (adds hourly cost).

---

## Hardening checklist

- [ ] Enable NAT or VPC endpoints for private subnet egress.
- [ ] Move DB password to Secrets Manager.
- [ ] Add HTTPS listener and ACM certificate on ALB.
- [ ] Enable RDS deletion protection in non-lab environments.
- [ ] Add ECS deployment circuit breaker and autoscaling.

---

## Cost warning

Creates billable resources: ALB, Fargate tasks, RDS, optional NAT gateway. Use a sandbox account.
