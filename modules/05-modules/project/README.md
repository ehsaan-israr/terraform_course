# Module 5 Project — Composing Reusable Modules

## Starting point and purpose

This project demonstrates **composing reusable Terraform modules** into a multi-tier AWS skeleton. The root module wires four local child modules: VPC → security groups → ECS + RDS.

**What you build:**

- A VPC with public/private subnets and optional NAT gateway.
- Tiered security groups (ALB, app, database).
- An ECS Fargate cluster and task definition (service disabled by default).
- An encrypted PostgreSQL RDS instance.

**Learning goals:** module inputs/outputs as contracts, passing values between modules, and root-module composition.

---

## Architecture

```text
+-------------------+
| Root module       |
| (environment glue)|
+---------+---------+
          |
          +-------------------+
          |                   |
          v                   v
  +---------------+    +-------------------+
  | vpc           | -> | security-groups   |
  +-------+-------+    +---------+---------+
          |                      |
          | subnet IDs           | SG IDs
          v                      v
  +---------------+    +-------------------+
  | ecs           |    | rds               |
  | cluster/task  |    | private database  |
  +---------------+    +-------------------+
```

---

## File index

### Root module

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.5.0`; AWS and random providers. |
| `providers.tf` | AWS provider configuration. |
| `variables.tf` | VPC CIDRs, AZs, NAT flag, app port, DB username, tags. |
| `main.tf` | Instantiates all four child modules and passes outputs between them. |
| `outputs.tf` | VPC/subnet IDs, ECS cluster, RDS endpoint, password warning. |
| `README.md` | This file. |

### `modules/vpc/`

| File | Purpose |
|------|---------|
| `main.tf` | VPC, IGW, public/private subnets, route tables, optional NAT. |
| `variables.tf` | CIDRs, AZs, NAT flag, tags. |
| `outputs.tf` | VPC ID, subnet IDs, route table IDs. |

### `modules/security-groups/`

| File | Purpose |
|------|---------|
| `main.tf` | ALB, app, and database SGs with tier-to-tier rules. |
| `variables.tf` | VPC ID, app/db ports, allowed HTTP CIDRs. |
| `outputs.tf` | ALB, app, database SG IDs. |

### `modules/ecs/`

| File | Purpose |
|------|---------|
| `main.tf` | ECS cluster, CloudWatch log group, IAM execution role, Fargate task def, optional service. |
| `variables.tf` | Subnets, SG, container image/port, CPU/memory, `create_service` flag. |
| `outputs.tf` | Cluster, task definition, execution role, optional service name. |

### `modules/rds/`

| File | Purpose |
|------|---------|
| `main.tf` | Random password, DB subnet group, encrypted PostgreSQL RDS. |
| `variables.tf` | Subnets, DB SG, engine version, instance class, storage. |
| `outputs.tf` | Endpoint, port, subnet group, sensitive generated password. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Networking** | `modules/vpc/main.tf` | VPC, subnets, IGW, route tables, optional NAT |
| **Security groups** | `modules/security-groups/main.tf` | ALB, app, database SGs and rules |
| **Compute (ECS/Fargate)** | `modules/ecs/main.tf`, root `main.tf` | ECS cluster, task definition, optional service |
| **Database (RDS)** | `modules/rds/main.tf`, root `main.tf` | PostgreSQL RDS, subnet group |
| **IAM** | `modules/ecs/main.tf` | ECS task execution role |
| **Monitoring** | `modules/ecs/main.tf` | CloudWatch log group, Container Insights |
| **Module composition** | root `main.tf` | Wires VPC subnets → ECS/RDS, VPC ID → SGs, SG IDs → ECS/RDS |

**Data flow in root `main.tf`:**

- `module.vpc.private_subnet_ids` → ECS and RDS
- `module.vpc.vpc_id` → security groups
- `module.security_groups.app_security_group_id` → ECS
- `module.security_groups.database_security_group_id` → RDS

---

## Run

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply    # Review cost first (RDS, optional NAT)
terraform destroy
```

ECS service is disabled by default (`create_service = false`). Enable after NAT or VPC endpoints, an application image, and load balancer wiring are in place.

---

## Learning tasks

1. Trace how `module.vpc.private_subnet_ids` flows into ECS and RDS in `main.tf`.
2. Set `enable_nat_gateway = true` and inspect the planned resources.
3. Add a new output from the VPC module (e.g., internet gateway ID).
4. Set `create_service = true` in the ECS module call and review the additional resources.

---

## Cost warning

This example creates billable resources (RDS, optional NAT gateway). Use a sandbox account and destroy when finished.
