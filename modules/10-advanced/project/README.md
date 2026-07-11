# Module 10 Project — Monolith to Modules Migration with `moved` Blocks

## Starting point and purpose

This project demonstrates **refactoring a monolithic root module into reusable modules without destroying AWS resources**, using Terraform **`moved` blocks** to preserve state lineage when resource addresses change.

**Study flow:** `before/monolith.tf` → `after/main.tf` + submodules → `after/moved.tf` → `after/MIGRATION.md`.

**Learning goals:** safe refactoring, `moved` block semantics, modular decomposition, and state address mapping.

---

## Architecture

```text
before/
  monolith.tf          --> Single file: VPC + SG + EC2

after/
  main.tf              --> Root composition
  moved.tf             --> State address remapping
  modules/
    networking/        --> VPC, IGW, subnet, routing
    security-group/    --> Web SG
    compute/           --> EC2 instance
```

---

## File index

### Project root

| File | Purpose |
|------|---------|
| `README.md` | This file — project overview and study steps. |

### `before/` — Pre-refactor monolith

| File | Purpose |
|------|---------|
| `monolith.tf` | Single file: VPC, IGW, subnet, routing, SG, EC2, outputs. |

### `after/` — Post-refactor modular layout

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform/provider version constraints. |
| `variables.tf` | Region, project name, AMI, instance type. |
| `main.tf` | Root composition of three modules. |
| `moved.tf` | Seven `moved` blocks mapping old → new addresses. |
| `outputs.tf` | Re-exports `vpc_id`, `instance_id` from modules. |
| `MIGRATION.md` | Address map, workflow, anti-patterns. |

### `after/modules/networking/`

| File | Purpose |
|------|---------|
| `main.tf` | VPC, IGW, subnet, route table, association. |
| `variables.tf` | Project, region, CIDR, tags. |
| `outputs.tf` | `vpc_id`, `public_subnet_id`. |

### `after/modules/security-group/`

| File | Purpose |
|------|---------|
| `main.tf` | HTTP + SSH ingress, all egress. |
| `variables.tf` | Project, VPC ID, tags. |
| `outputs.tf` | `security_group_id`. |

### `after/modules/compute/`

| File | Purpose |
|------|---------|
| `main.tf` | `aws_instance.this`. |
| `variables.tf` | AMI, instance type, subnet, SGs, tags. |
| `outputs.tf` | `instance_id`. |

---

## Feature → file mapping

| Feature | Before | After |
|---------|--------|-------|
| **VPC + networking** | `before/monolith.tf` | `after/modules/networking/main.tf` |
| **Security group** | `before/monolith.tf` | `after/modules/security-group/main.tf` |
| **EC2 compute** | `before/monolith.tf` | `after/modules/compute/main.tf` |
| **Root composition** | — | `after/main.tf` |
| **State-preserving migration** | — | `after/moved.tf`, `after/MIGRATION.md` |
| **Outputs** | `before/monolith.tf` | `after/outputs.tf` |

After refactor, addresses become e.g. `module.networking.aws_vpc.this`, `module.web.aws_instance.this`.

---

## Run

### Study the monolith

```bash
cd before
terraform init
terraform plan -var='ami_id=ami-xxxxxxxx'   # requires real AMI
```

### Migrate to modular layout (same state file)

```bash
cd ../after
terraform init
terraform plan -var='ami_id=ami-xxxxxxxx'
# Expect "moved" operations, not destroy/create
terraform apply -var='ami_id=ami-xxxxxxxx'
```

Follow the staged workflow in `after/MIGRATION.md`.

---

## Key resources (same logical stack)

- `aws_vpc`, `aws_internet_gateway`, `aws_subnet`, `aws_route_table`, `aws_route_table_association`
- `aws_security_group` (HTTP from anywhere, SSH from `10.0.0.0/8`)
- `aws_instance` (public subnet, associated public IP)
