# Module 03 Exercise: VPC Networking Module

## Objective

Design and implement a reusable Terraform module that provisions a multi-AZ VPC with public and private subnets, Internet Gateway, NAT Gateway, and route tables—ready to be consumed by an EKS module in Module 04.

---

## Requirements

1. Terraform >= 1.5, AWS provider `~> 5.0`.
2. VPC with configurable CIDR (default `10.0.0.0/16`).
3. Two Availability Zones minimum.
4. Two public subnets and two private subnets with non-overlapping CIDRs.
5. Internet Gateway attached to the VPC.
6. At least one NAT Gateway in a public subnet.
7. Separate public and private route tables with correct routes.
8. All resources tagged with `Environment`, `Project`, `ManagedBy`.
9. EKS subnet discovery tags on appropriate subnets.
10. Example root module that calls your VPC module and exports key outputs.

---

## Constraints

- Use a **single NAT Gateway** to minimize cost unless you document why you chose NAT per AZ.
- Do not create unnecessary resources (VPN, Transit Gateway, etc.).
- Subnet CIDRs must fit inside the VPC CIDR without overlap.
- Module must not hard-code `project_name` or `environment`—accept via variables.
- Enable DNS hostnames and DNS support on the VPC.

---

## Tasks

### Task 1: Module Scaffold

Create `modules/vpc/` with `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`.

### Task 2: VPC and Subnets

1. Create `aws_vpc` with DNS support enabled.
2. Create public subnets with `map_public_ip_on_launch = true`.
3. Create private subnets without public IP mapping.
4. Spread subnets across two AZs.

### Task 3: Gateways and Routing

1. Create and attach Internet Gateway.
2. Allocate Elastic IP for NAT Gateway.
3. Create NAT Gateway in the **first** public subnet.
4. Public route table: `0.0.0.0/0` → IGW, associated with all public subnets.
5. Private route table: `0.0.0.0/0` → NAT, associated with all private subnets.

### Task 4: EKS Tags

Add to public subnets:

```hcl
"kubernetes.io/role/elb" = "1"
```

Add to private subnets:

```hcl
"kubernetes.io/role/internal-elb" = "1"
```

Include `kubernetes.io/cluster/<cluster-name> = "shared"` tag pattern via variable for cluster name (used in Module 04).

### Task 5: Module Interface

**Required variables (minimum):**

| Variable | Purpose |
| --- | --- |
| `name_prefix` | Naming prefix for all resources |
| `vpc_cidr` | VPC CIDR block |
| `availability_zones` | List of 2+ AZ names |
| `public_subnet_cidrs` | CIDRs for public subnets |
| `private_subnet_cidrs` | CIDRs for private subnets |
| `tags` | Common tags map |
| `cluster_name` | EKS cluster name for subnet tags |

**Required outputs (minimum):**

| Output | Purpose |
| --- | --- |
| `vpc_id` | VPC identifier |
| `vpc_cidr_block` | VPC CIDR |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_public_ip` | NAT EIP (for troubleshooting) |

### Task 6: Root Example

Create a root `main.tf` that:

1. Configures the AWS provider with `default_tags`.
2. Calls the VPC module.
3. Exposes outputs for downstream EKS use.

### Task 7: Apply and Verify

```bash
terraform init
terraform plan
terraform apply
```

Verify routing and subnet layout via AWS Console or CLI.

---

## Expected Deliverables

| Deliverable | Description |
| --- | --- |
| `modules/vpc/` | Complete reusable module |
| Root example | `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` |
| `terraform.tfvars.example` | Documented example values |
| `.gitignore` | Standard Terraform ignores |
| Applied VPC | Running in AWS with 2 AZs |

---

## Validation Checklist

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` succeeds
- [ ] VPC has `enable_dns_hostnames` and `enable_dns_support` true
- [ ] Exactly 2 public and 2 private subnets (for default example)
- [ ] Subnets span at least 2 different AZs
- [ ] Internet Gateway attached to VPC
- [ ] NAT Gateway in public subnet, state available
- [ ] Public RT: `0.0.0.0/0` → igw-*
- [ ] Private RT: `0.0.0.0/0` → nat-*
- [ ] Tags `Environment`, `Project`, `ManagedBy` on VPC and subnets
- [ ] EKS ELB role tags on correct subnet tiers
- [ ] Module outputs consumed successfully at root level
- [ ] `terraform destroy` removes all resources cleanly
- [ ] No hard-coded account IDs or regions inside the module

---

**When finished:** Compare with `solution/` and read `SOLUTION.md`.
