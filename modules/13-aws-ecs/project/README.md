# Module 13 project — ECS Fargate service

Hands-on lab for [Module 13](../README.md). This stack teaches the ECS path
only: VPC → ALB → Fargate service → CloudWatch. No RDS.

**Learning goals:** cluster vs task definition vs service, execution role vs
task role, `target_type = ip`, and the lab-vs-production networking tradeoff.

---

## Architecture

```text
Internet
   |
ALB (public subnets)
   |
ECS Fargate task
   |-- lab default: public subnet + public IP (no NAT cost)
   `-- production: private subnet + NAT or VPC endpoints
   |
CloudWatch Logs
```

---

## File index

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.5.0`; AWS provider. |
| `providers.tf` | AWS provider region. |
| `variables.tf` | VPC, image, desired count, public IP flag, NAT flag. |
| `network.tf` | VPC, subnets, IGW, optional NAT. |
| `security.tf` | ALB and task security groups; execution and task IAM roles. |
| `alb.tf` | Public ALB, IP target group, HTTP listener. |
| `ecs.tf` | Cluster, Fargate task definition, service. |
| `monitoring.tf` | Log group, ALB 5xx alarm, ECS CPU alarm. |
| `outputs.tf` | ALB DNS, cluster/service names, both IAM role ARNs. |

**Traffic path:** Internet → ALB:80 → task `app_port` (default 80) → nginx

---

## Run

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan
# terraform apply    # ALB is the main hourly cost; Fargate is extra while count > 0
terraform output alb_dns_name
terraform destroy
```

Set `ecs_desired_count = 0` if you only want to inspect the plan.

Default `assign_public_ip = true` so tasks can pull the public nginx image
without a NAT gateway. That is a **lab shortcut**. Production tasks belong in
private subnets with `assign_public_ip = false`.

---

## Hardening checklist

- [ ] `assign_public_ip = false` and private subnets.
- [ ] NAT or VPC endpoints for ECR, logs, and secrets.
- [ ] Replace public nginx with an ECR image tagged by git SHA.
- [ ] HTTPS listener and ACM certificate.
- [ ] Autoscaling policy (see exercises).
- [ ] Real `/health` path instead of `/`.

---

## Cost warning

Creates a billable ALB and (if desired count > 0) Fargate tasks. Optional NAT
adds more hourly cost. Use a sandbox account and destroy when finished.
