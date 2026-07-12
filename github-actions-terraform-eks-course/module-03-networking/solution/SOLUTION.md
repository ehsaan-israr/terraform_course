# Module 03 Solution: VPC Networking Module

Detailed explanation of the reusable VPC module and example root module.

---

## Module `variables.tf`

```hcl
variable "availability_zones" {
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required for EKS."
  }
}
```

EKS enforces multi-AZ; fail early in the module contract.

```hcl
variable "single_nat_gateway" {
  type    = bool
  default = true
}
```

When `true`, one NAT GW and one private route table—cost-efficient. Set `false` for NAT per AZ in production.

```hcl
variable "cluster_name" {
  default = ""
}
```

When set, adds `kubernetes.io/cluster/<name> = "shared"` tag for EKS load balancer subnet discovery.

---

## Module `main.tf` — VPC

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

DNS hostnames required for EKS private endpoint resolution inside the VPC.

---

## Subnets with `count`

```hcl
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone         = var.availability_zones[count.index]
  map_public_ip_on_launch = true
```

`count.index` maps subnet CIDR to AZ by position—`public_subnet_cidrs[0]` in `availability_zones[0]`.

```hcl
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  }, var.cluster_name != "" ? {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } : {}, {
    "kubernetes.io/role/elb" = "1"
  })
}
```

Public subnets get ELB role tag for internet-facing load balancers.

---

## Internet Gateway

```hcl
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}
```

Single IGW per VPC; shared by all public subnets.

---

## NAT Gateway

```hcl
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  domain = "vpc"
}
```

EIP must be in VPC scope (`domain = "vpc"`) for NAT Gateway.

```hcl
resource "aws_nat_gateway" "this" {
  count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id       = aws_subnet.public[count.index].id
}
```

NAT is always placed in a **public** subnet with route to IGW.

---

## Route Tables

```hcl
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}
```

Public default route targets IGW.

```hcl
resource "aws_route" "private_nat" {
  count = var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}
```

Private default route targets NAT—outbound only.

---

## Root `main.tf`

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  cluster_name         = "${local.name_prefix}-eks"
  ...
}
```

Uses data source for AZs so configuration is portable across accounts/regions.

---

## Downstream Use (Module 04)

Module 04 consumes:

```hcl
vpc_id             = module.vpc.vpc_id
private_subnet_ids = module.vpc.private_subnet_ids
```

Worker nodes launch in private subnets; control plane ENIs span subnets provided.
