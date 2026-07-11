# Module 2 Solutions - Terraform Basics

These answers correspond to `../exercises/README.md` and use the project in
`../project`.

## Exercise 1: Add variable validation

Add a variable for HTTP ingress in `variables.tf`:

```hcl
variable "allowed_http_cidr" {
  description = "CIDR block allowed to reach the web server over HTTP."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_http_cidr, 0))
    error_message = "allowed_http_cidr must be a valid CIDR block, for example 203.0.113.0/24."
  }
}
```

Then replace the hard-coded HTTP rule in `main.tf`:

```hcl
resource "aws_security_group" "web" {
  # ...

  ingress {
    description = "HTTP from approved CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_http_cidr]
  }
}
```

A useful test with valid input:

```bash
terraform plan \
  -var='allowed_ssh_cidr=203.0.113.10/32' \
  -var='allowed_http_cidr=198.51.100.0/24'
```

A useful test with invalid input:

```bash
terraform plan \
  -var='allowed_ssh_cidr=203.0.113.10/32' \
  -var='allowed_http_cidr=not-a-cidr'
```

The invalid run should fail before AWS calls are made because
`cidrhost(var.allowed_http_cidr, 0)` throws for invalid CIDR syntax and
`can(...)` converts that thrown error into `false`.

### Sample diff

```diff
+variable "allowed_http_cidr" {
+  description = "CIDR block allowed to reach the web server over HTTP."
+  type        = string
+  default     = "0.0.0.0/0"
+
+  validation {
+    condition     = can(cidrhost(var.allowed_http_cidr, 0))
+    error_message = "allowed_http_cidr must be a valid CIDR block, for example 203.0.113.0/24."
+  }
+}
```

```diff
   ingress {
-    description = "HTTP from anywhere"
+    description = "HTTP from approved CIDR"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
-    cidr_blocks = ["0.0.0.0/0"]
+    cidr_blocks = [var.allowed_http_cidr]
   }
```

## Exercise 2: Turn outputs into a small API

Add these outputs to `outputs.tf`:

```hcl
output "security_group_id" {
  description = "Security group ID attached to the web instance."
  value       = aws_security_group.web.id
}

output "ami_id" {
  description = "AMI ID selected by the Amazon Linux 2023 data source."
  value       = data.aws_ami.amazon_linux_2023.id
}

output "subnet_availability_zone" {
  description = "Availability zone for the subnet selected for the web instance."
  value       = aws_instance.web.availability_zone
}
```

Plan-time behavior:

- `ami_id` is usually known during plan because `data.aws_ami.amazon_linux_2023`
  is read during planning.
- `security_group_id` is known after apply because AWS assigns the security
  group ID when it creates `aws_security_group.web`.
- `subnet_availability_zone` may be shown as known after apply when read from
  `aws_instance.web`, because it is an attribute of a resource not yet created.

If you want the selected subnet's Availability Zone to be known during plan,
introduce a subnet data source and output from that instead:

```hcl
data "aws_subnet" "selected" {
  id = sort(data.aws_subnets.default.ids)[0]
}

output "selected_subnet_availability_zone" {
  description = "Availability zone of the subnet selected for the web instance."
  value       = data.aws_subnet.selected.availability_zone
}
```

That version is a better API when downstream automation needs the AZ before
apply.

## Exercise 3: Refactor repeated tags with locals

Add an `owner` variable:

```hcl
variable "owner" {
  description = "Team or person responsible for these resources."
  type        = string
  default     = "platform-team"
}
```

Update `local.common_tags`:

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Course      = "aws-terraform-production-engineering"
    Module      = "02-terraform-basics"
    Owner       = var.owner
  }
}
```

The project's provider uses AWS `default_tags`, so supported AWS resources will
receive `Owner` without adding it to every resource block. Resource-specific
`tags` can still set `Name` or intentional exceptions:

```hcl
resource "aws_instance" "web" {
  # ...

  tags = {
    Name = "${local.name_prefix}-web"
  }
}
```

Expected plan shape:

```text
~ tags_all = {
    + "Owner" = "platform-team"
      # existing tags omitted
  }
```

This reduces copy-paste and gives reviewers one central place to check required
tags.
