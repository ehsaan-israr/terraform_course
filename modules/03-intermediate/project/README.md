# Module 3 Project — Multi-Server App with Intermediate Terraform Patterns

## Starting point and purpose

This project teaches **intermediate Terraform patterns**: `for_each`, dynamic blocks, conditional resources, sensitive variables/outputs, and a commented `prevent_destroy` lifecycle guard. You provision multiple EC2 instances (default: three) in the default VPC.

**What you build:**

- A security group with dynamic ingress rules from a map variable.
- Multiple EC2 instances keyed by a `servers` map (`for_each`).
- Optional Elastic IPs per server (conditional on `create_elastic_ips`).

**Learning goals:** map-based iteration, dynamic blocks, conditional creation, sensitive data handling, and lifecycle rules.

---

## Architecture

```text
                    +-- web-a (EC2) --+
Internet --> SG --> +-- web-b (EC2) --+--> optional EIPs
                    +-- worker-a (EC2) -+
```

Subnets are assigned round-robin from the default VPC via `locals.tf`.

---

## File index

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.6.0`, AWS provider `~> 5.0`. |
| `providers.tf` | AWS provider with default tags from locals. |
| `locals.tf` | Name prefix, tags, round-robin subnet assignment per server. |
| `variables.tf` | Servers map, ingress rules map, conditional EIP flag, sensitive `admin_password`. |
| `main.tf` | Data sources, dynamic security group, `for_each` instances and EIPs. |
| `outputs.tf` | Account ID, AMI, server IDs/IPs, web URLs, sensitive password. |
| `terraform.tfvars.example` | Full example with servers and ingress rules. |
| `.gitignore` | Standard Terraform ignores. |
| `.terraform.lock.hcl` | Provider version lock file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Multi-instance compute** | `main.tf` | `aws_instance.server` (`for_each` over `var.servers`) |
| **Optional Elastic IPs** | `main.tf` | `aws_eip.server` (conditional `for_each`) |
| **Dynamic security group** | `main.tf`, `variables.tf` | `aws_security_group.app` with dynamic ingress blocks |
| **Subnet placement** | `locals.tf` | Round-robin mapping of servers to subnets |
| **Secrets / sensitive data** | `variables.tf`, `outputs.tf` | `admin_password` (sensitive input and output) |
| **Lifecycle protection** | `main.tf` | Commented `prevent_destroy` on instances |

---

## Prerequisites

- Terraform 1.6+, AWS credentials, EC2/security group permissions.

---

## Configure

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit ssh CIDR in ingress_rules and set admin_password
```

---

## Run

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
terraform output -raw admin_password   # sensitive
terraform destroy
```

If `prevent_destroy` is uncommented in `main.tf`, destroy will fail until re-commented.

---

## Troubleshooting

- **Too many instances for subnets:** Reduce the `servers` map or ensure enough default subnets exist.
- **Sensitive output hidden:** Use `terraform output -raw admin_password`.
