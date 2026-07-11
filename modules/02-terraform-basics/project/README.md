# Module 2 Project — Web Server with Security Group, EC2, and Elastic IP

## Starting point and purpose

This project builds on Module 1 by introducing **Terraform basics**: `locals`, implicit dependencies, variable validation, and **Elastic IP** for a stable public address. You provision a single nginx web server in the default VPC.

**What you build:**

- A security group with HTTP and SSH rules.
- An EC2 instance with nginx installed via `user_data`.
- An Elastic IP associated with the instance.

**Learning goals:** shared naming via `locals`, implicit resource dependencies, validated variables, and stable public addressing.

---

## Architecture

```text
Internet
   |
   +-- HTTP :80 --> Security Group --> EC2 (nginx)
   |
   +-- SSH :22 (trusted CIDR only)
   |
Elastic IP (stable public IP) --> EC2
```

---

## File index

| File | Purpose |
|------|---------|
| `versions.tf` | Pins Terraform `>= 1.6.0` and AWS provider `~> 5.0`. |
| `providers.tf` | AWS provider; applies `local.common_tags` as default tags. |
| `locals.tf` | Shared `name_prefix` and `common_tags` used across resources. |
| `variables.tf` | Region, project name (validated), environment (dev/staging/prod), instance type, SSH CIDR, optional key pair. |
| `main.tf` | Data sources, security group, EC2 instance, Elastic IP. |
| `outputs.tf` | Instance ID, Elastic IP, public DNS, web URL, example SSH command. |
| `terraform.tfvars.example` | Example variable values. |
| `.gitignore` | Standard Terraform ignores. |
| `.terraform.lock.hcl` | Provider version lock file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **Compute (EC2 + EIP)** | `main.tf` | `aws_instance.web`, `aws_eip.web` |
| **Security / networking** | `main.tf` | `aws_security_group.web`; default VPC data sources |
| **Naming and tagging** | `locals.tf`, `providers.tf` | `name_prefix`, `common_tags` |
| **Configuration** | `variables.tf`, `versions.tf` | Validated inputs, provider constraints |
| **Post-apply visibility** | `outputs.tf` | Elastic IP, `web_url`, SSH command |

---

## Prerequisites

- Terraform 1.6+, AWS credentials, permissions for EC2/EIP/security groups in `us-east-1`.

---

## Configure

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit allowed_ssh_cidr to your public IP/32
```

---

## Run

Single root — EIP depends on the instance implicitly.

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output web_url
terraform destroy
```

---

## Troubleshooting

- **EIP limit reached:** Release unused Elastic IPs in the AWS console.
- **Web page does not load:** Wait for `user_data`, verify security group and instance status.
