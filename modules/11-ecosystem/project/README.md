# Module 11 Project — Terragrunt, Atlantis, and Infracost

## Starting point and purpose

This project provides a **minimal Terragrunt live layout** with a reusable VPC module, plus lightweight examples of **Atlantis** (PR-driven Terraform) and **Infracost** (cost estimates on PRs).

**Learning goals:** DRY remote state with Terragrunt, generated provider blocks, environment-specific inputs, and comparing Terragrunt vs Atlantis vs Terraform Cloud.

---

## Architecture

```text
terragrunt/
  root.hcl                    --> Shared remote state + generated provider
  env/dev/terragrunt.hcl      --> Dev live config
  modules/vpc/                --> Reusable VPC module

atlantis.yaml                 --> PR-driven plan/apply
.github/workflows/infracost-comment.yml  --> PR cost comments
```

---

## File index

### Project root

| File | Purpose |
|------|---------|
| `README.md` | This file — structure, implementation steps, tool comparison. |
| `atlantis.yaml` | Atlantis project config for `terragrunt/env/dev`. |
| `.github/workflows/infracost-comment.yml` | PR cost comment via Infracost breakdown. |

### `terragrunt/`

| File | Purpose |
|------|---------|
| `root.hcl` | Remote state (S3), generated `provider.tf`. |
| `env/dev/terragrunt.hcl` | Dev live config: includes root, points at VPC module, sets inputs. |

### `terragrunt/modules/vpc/`

| File | Purpose |
|------|---------|
| `main.tf` | VPC + private subnets per AZ. |
| `variables.tf` | Name, CIDR, AZs, tags. |
| `outputs.tf` | `vpc_id`, `private_subnet_ids`. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources / behavior |
|---------|-------------------|--------------------------|
| **DRY remote state** | `terragrunt/root.hcl` | S3 backend config shared across envs |
| **Generated provider** | `terragrunt/root.hcl` | `generate "provider"` block |
| **Environment inputs** | `terragrunt/env/dev/terragrunt.hcl` | CIDR, AZs, tags per env |
| **Reusable VPC module** | `terragrunt/modules/vpc/*` | `aws_vpc.this`, `aws_subnet.private` |
| **Atlantis PR workflow** | `atlantis.yaml` | Plan/apply via Terragrunt on PR comments |
| **Cost estimation** | `.github/workflows/infracost-comment.yml` | Infracost breakdown on PRs |

---

## Prerequisites

- S3 bucket `example-terraform-state-ecosystem-demo`
- DynamoDB table `example-terraform-locks-ecosystem-demo`
- AWS credentials configured

---

## Run

```bash
cd terragrunt/env/dev
terragrunt init
terragrunt plan
# terragrunt apply
```

**Atlantis:** Configure an Atlantis server with this repo; it reads `atlantis.yaml`.

**Infracost:** Runs on PRs touching `modules/11-ecosystem/project/**`.

---

## Tool comparison

| Tool | Role in this project |
|------|---------------------|
| **Terragrunt** | DRY backend config, generated providers, env inputs |
| **Atlantis** | PR-driven plan/apply with approval gates |
| **Infracost** | Cost visibility before merge |
