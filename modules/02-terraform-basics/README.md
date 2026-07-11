# Module 2 - Terraform Basics

Module 1 explained why Terraform exists. This module teaches the daily Terraform skills you need to write, read, and operate small AWS configurations professionally.

You will learn installation, CLI workflow, HCL syntax, resources, variables, outputs, locals, expressions, functions, dependencies, and resource references. The project builds a simple web server environment in `us-east-1` with a security group, EC2 instance, and Elastic IP.

---

## 1. Installation

### Concept

Terraform is distributed as a single CLI binary. The CLI reads `.tf` files, downloads provider plugins, creates plans, applies changes, and manages state.

Verify installation:

```bash
terraform version
```

### Why it exists

Terraform must run consistently across laptops and CI systems. Version mismatches can create confusing behavior, especially when teams use different Terraform or provider versions.

### Real-world use cases

- Local development plans before opening a pull request.
- CI validation with `terraform fmt` and `terraform validate`.
- Automated production applies from a deployment workflow.
- Emergency drift investigation from a controlled operator workstation.

### ASCII diagram

```text
developer laptop          CI runner
      |                       |
      v                       v
terraform CLI version   terraform CLI version
      |                       |
      +----------+------------+
                 |
                 v
        same configuration behavior
```

### Step-by-step installation options

On Linux, use your package manager or download from HashiCorp releases. In production teams, prefer a version manager or pinned CI image.

Example with a version manager such as `tfenv` or `mise`:

```bash
terraform version
terraform -install-autocomplete
```

Add a required version to configuration:

```hcl
terraform {
  required_version = ">= 1.6.0"
}
```

### Production best practices

- Pin `required_version` in every root module.
- Use the same Terraform version in CI and production apply jobs.
- Commit `.terraform.lock.hcl` so provider selections are repeatable.
- Upgrade Terraform intentionally and test plans in lower environments first.

### Common mistakes and troubleshooting

- **Mistake:** Different developers use different Terraform versions.
  - **Fix:** Use `required_version` and a version manager.
- **Mistake:** Installing Terraform but not providers.
  - **Fix:** Run `terraform init` in each working directory.
- **Mistake:** Assuming provider versions are controlled by Terraform CLI version.
  - **Fix:** Providers are separate plugins with separate version constraints.

---

## 2. Terraform CLI Workflow

### Concept

The Terraform CLI provides the workflow for infrastructure changes:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

### Why it exists

Infrastructure changes need a repeatable sequence. The CLI separates setup, validation, planning, and execution.

### Real-world use cases

- Pull request checks run `fmt`, `validate`, and `plan`.
- Production deploy jobs run `apply` after approval.
- Operators run `state` and `output` commands during incident response.
- Teams use `workspace` only in limited cases; separate directories/backends are often clearer for production.

### ASCII diagram

```text
init -> fmt -> validate -> plan -> review -> apply -> output
```

### Step-by-step example

```bash
# Download provider plugins and initialize backend.
terraform init

# Format all Terraform files under the current directory.
terraform fmt -recursive

# Check syntax and provider schemas.
terraform validate

# Preview changes.
terraform plan -out=tfplan

# Apply exactly what was reviewed.
terraform apply tfplan

# Show values exported by outputs.tf.
terraform output
```

Useful inspection commands:

```bash
terraform providers
terraform state list
terraform state show aws_instance.web
terraform console
```

### Production best practices

- Use saved plan files when human approval and apply happen in separate steps.
- Avoid `-auto-approve` outside controlled automation.
- Keep `terraform destroy` access restricted.
- Review plans for deletes and replacements, not just creates.
- Put common CLI flags into automation, not developer memory.

### Common mistakes and troubleshooting

- **Mistake:** Running `apply` without reviewing plan.
  - **Fix:** Use `plan -out=tfplan` and apply the plan file.
- **Mistake:** Forgetting `terraform init` after changing providers/modules.
  - **Fix:** Re-run `init` when Terraform tells you the dependency lock file or providers changed.
- **Mistake:** Running commands from the wrong directory.
  - **Fix:** Terraform loads `.tf` files in the current directory only.

---

## 3. HCL Syntax

### Concept

Terraform uses HashiCorp Configuration Language (HCL). HCL is declarative and built around blocks, arguments, expressions, and references.

```hcl
block_type "label_one" "label_two" {
  argument = expression

  nested_block {
    argument = expression
  }
}
```

Example:

```hcl
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP"

  tags = {
    Name      = "web-sg"
    ManagedBy = "terraform"
  }
}
```

### Why it exists

HCL gives infrastructure code a clear shape:

- Blocks represent Terraform concepts.
- Arguments configure those concepts.
- Expressions calculate values.
- References connect resources.

### Real-world use cases

- Defining cloud resources.
- Building strings for names and tags.
- Passing maps and objects into reusable modules.
- Using conditions to enable optional behavior.

### ASCII diagram

```text
resource "aws_instance" "web" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
}

resource type: aws_instance
resource name: web
arguments:    ami, instance_type
references:   data.aws_ami.al2023.id, var.instance_type
```

### Step-by-step example

Declare variables, create a local value, then use both in a resource:

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

locals {
  name_prefix = "payments-${var.environment}"
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name_prefix}-artifacts-12345"
}
```

### Production best practices

- Run `terraform fmt` before committing.
- Use descriptive resource names such as `web`, `app`, or `logs`, not `this` everywhere in root modules.
- Keep names stable; renaming a resource block changes its Terraform address.
- Prefer typed variables over untyped `any`.
- Keep complex expressions readable with locals.

### Common mistakes and troubleshooting

- **Mistake:** Missing quotes around strings.
  - **Fix:** Use `"string"` unless referencing a symbol.
- **Mistake:** Confusing maps and objects.
  - **Fix:** Maps have one value type; objects have named attributes with specific types.
- **Mistake:** Renaming resources casually.
  - **Fix:** Use `terraform state mv` or `moved` blocks when renaming managed resources.

---

## 4. Resources

### Concept

Resources describe infrastructure objects Terraform should manage. A resource has a type, a local name, arguments, and attributes exported after creation.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}
```

Terraform address:

```text
aws_instance.web
```

### Why it exists

Resources are the main unit of desired infrastructure. Terraform uses them to compare configuration, state, and real infrastructure.

### Real-world use cases

- `aws_instance` for EC2.
- `aws_security_group` for firewall rules.
- `aws_s3_bucket` for object storage.
- `aws_lb` for load balancers.
- `aws_db_instance` for RDS.

### ASCII diagram

```text
resource block -> Terraform state address -> AWS remote object

aws_instance.web -> aws_instance.web -> i-0123456789abcdef0
```

### Step-by-step example

```hcl
resource "aws_security_group" "web" {
  name        = "basic-web"
  description = "Allow web traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Then reference it:

```hcl
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

### Production best practices

- Use separate resources for settings the AWS provider models separately, such as S3 versioning.
- Prefer explicit tags.
- Avoid hard-coding account-specific IDs unless there is a reason.
- Read provider documentation for arguments that force replacement.
- Keep resource names stable for long-lived infrastructure.

### Common mistakes and troubleshooting

- **Mistake:** Editing infrastructure manually after Terraform creates it.
  - **Fix:** Change Terraform code and apply.
- **Mistake:** Deleting a resource block without realizing Terraform will destroy the object.
  - **Fix:** Review plans carefully; use `removed` blocks or state operations only when intentionally stopping management.
- **Mistake:** Ignoring provider deprecation warnings.
  - **Fix:** Update code before provider upgrades make warnings into errors.

---

## 5. Variables

### Concept

Input variables parameterize Terraform configuration. They let you reuse code with different values for environment, instance type, CIDR blocks, names, and feature flags.

```hcl
variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}
```

Use the value:

```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

### Why it exists

Hard-coded infrastructure is difficult to reuse. Variables let the same configuration support dev, staging, and production with controlled differences.

### Real-world use cases

- Different instance sizes by environment.
- Different allowed SSH CIDR ranges.
- Optional Elastic IP creation.
- Standard tags from platform automation.

### ASCII diagram

```text
terraform.tfvars ----+
environment variable +--> variable "instance_type" --> var.instance_type
CLI -var -----------+
default ------------+
```

### Step-by-step example

```hcl
variable "allowed_ssh_cidr" {
  description = "Trusted SSH source."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr must be a valid CIDR block."
  }
}
```

Set values with:

```bash
terraform plan -var="allowed_ssh_cidr=203.0.113.10/32"
```

or:

```hcl
# terraform.tfvars
allowed_ssh_cidr = "203.0.113.10/32"
```

### Production best practices

- Use descriptions and types for every variable.
- Validate dangerous inputs such as CIDR blocks.
- Avoid storing secrets in `.tfvars` committed to Git.
- Prefer environment-specific variable files generated or managed by automation.
- Use `nullable = false` when a variable must not be null.

### Common mistakes and troubleshooting

- **Mistake:** Committing `terraform.tfvars` with private values.
  - **Fix:** Commit only `terraform.tfvars.example`.
- **Mistake:** Using string variables for structured data.
  - **Fix:** Use object, map, list, set, or bool types.
- **Mistake:** Expecting variable defaults to override `.tfvars`.
  - **Fix:** Terraform variable precedence gives explicit values priority.

---

## 6. Outputs

### Concept

Outputs expose selected values after apply. They are useful for humans, automation, and downstream Terraform configurations.

```hcl
output "web_url" {
  description = "Public URL for the web server."
  value       = "http://${aws_eip.web.public_dns}"
}
```

### Why it exists

Infrastructure creates values that callers need:

- Load balancer DNS names.
- S3 bucket names.
- Database endpoints.
- IAM role ARNs.
- Instance public IPs.

### Real-world use cases

- CI prints a preview environment URL.
- A deployment pipeline reads an ECR repository URL.
- Another Terraform stack consumes remote state outputs.
- Operators inspect outputs during testing.

### ASCII diagram

```text
aws_instance.web.public_ip
          |
          v
output "public_ip"
          |
          v
terraform output public_ip
```

### Step-by-step example

```hcl
output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.web.id
}

output "ssh_command" {
  description = "Example SSH command."
  value       = var.key_name == null ? "SSH disabled" : "ssh ec2-user@${aws_eip.web.public_ip}"
}
```

### Production best practices

- Output values that are useful, not every attribute.
- Mark secret outputs with `sensitive = true`.
- Avoid outputting passwords when an ARN or secret name is enough.
- Keep output names stable for downstream consumers.

### Common mistakes and troubleshooting

- **Mistake:** Assuming `sensitive = true` removes values from state.
  - **Fix:** It hides CLI display but state still needs protection.
- **Mistake:** Changing output names without checking consumers.
  - **Fix:** Treat outputs as an API.
- **Mistake:** Outputting values not available until apply and expecting them during plan.
  - **Fix:** Understand `(known after apply)`.

---

## 7. Locals

### Concept

Local values assign names to expressions inside a module. They reduce duplication and make configuration easier to read.

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

### Why it exists

Production Terraform often repeats naming and tagging logic. Locals centralize that logic without exposing it as user input.

### Real-world use cases

- Consistent resource names.
- Common tags.
- Derived CIDR lists.
- Feature-specific maps.
- Readable aliases for complex expressions.

### ASCII diagram

```text
variables -> locals -> resources

var.project_name + var.environment -> local.name_prefix -> resource names
```

### Step-by-step example

```hcl
locals {
  name_prefix = lower("${var.project_name}-${var.environment}")
}

resource "aws_eip" "web" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-web-eip"
  }
}
```

### Production best practices

- Use locals for derived values, not for values that callers should configure.
- Keep locals near the top-level concepts they support.
- Avoid giant locals blocks full of unrelated data.
- Prefer locals over copy-pasted string templates.

### Common mistakes and troubleshooting

- **Mistake:** Treating locals like mutable variables.
  - **Fix:** Locals are immutable expressions.
- **Mistake:** Hiding important inputs in locals.
  - **Fix:** Use variables when callers need control.
- **Mistake:** Creating deeply nested local transformations.
  - **Fix:** Split complex logic into smaller locals or modules.

---

## 8. Expressions

### Concept

Expressions compute values. HCL expressions include references, operators, conditionals, for expressions, splats, and function calls.

```hcl
var.environment == "prod" ? "t3.small" : "t3.micro"
```

### Why it exists

Infrastructure configuration needs controlled variability without becoming a general-purpose program.

### Real-world use cases

- Choose instance size by environment.
- Build names from variables.
- Filter enabled services.
- Generate tag maps.
- Conditionally include optional values.

### ASCII diagram

```text
inputs + operators + functions
             |
             v
       final argument value
```

### Step-by-step examples

String interpolation:

```hcl
name = "${var.project_name}-${var.environment}-web"
```

Conditional:

```hcl
instance_type = var.environment == "prod" ? "t3.small" : "t3.micro"
```

For expression:

```hcl
locals {
  upper_names = [for name in var.server_names : upper(name)]
}
```

Map merge:

```hcl
tags = merge(local.common_tags, {
  Name = "${local.name_prefix}-web"
})
```

### Production best practices

- Keep expressions understandable in plans and reviews.
- Move repeated or complex expressions into locals.
- Use typed variables so expressions fail early.
- Prefer explicit maps over clever transformations for critical infrastructure.

### Common mistakes and troubleshooting

- **Mistake:** Writing expressions that are too clever to review.
  - **Fix:** Optimize for maintainability.
- **Mistake:** Mixing list and set assumptions.
  - **Fix:** Use `tolist`, `toset`, and `sort` intentionally.
- **Mistake:** Forgetting that unknown values can propagate through expressions.
  - **Fix:** Values computed by providers may be known only after apply.

---

## 9. Functions

### Concept

Terraform functions transform values. Common functions include `join`, `split`, `format`, `lower`, `merge`, `lookup`, `length`, `cidrhost`, `file`, and `templatefile`.

```hcl
locals {
  normalized_name = lower(replace(var.project_name, "_", "-"))
}
```

### Why it exists

Functions let you keep configuration declarative while still handling practical data shaping.

### Real-world use cases

- Normalize resource names.
- Merge common and resource-specific tags.
- Validate CIDR input.
- Render user data scripts.
- Select values from maps.

### ASCII diagram

```text
var.project_name = "Payments_API"
          |
          v
replace("_", "-") -> lower()
          |
          v
"payments-api"
```

### Step-by-step examples

Validate CIDR:

```hcl
validation {
  condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
  error_message = "allowed_ssh_cidr must be a valid CIDR block."
}
```

Merge tags:

```hcl
tags = merge(local.common_tags, {
  Name = "${local.name_prefix}-web"
})
```

Render user data:

```hcl
user_data = templatefile("${path.module}/user_data.sh.tftpl", {
  title = "Terraform Basics"
})
```

### Production best practices

- Use `templatefile` for long scripts instead of huge inline strings.
- Use `try` sparingly; do not hide invalid inputs.
- Prefer `lookup(map, key, default)` when a missing key is expected.
- Use `can` in variable validation.

### Common mistakes and troubleshooting

- **Mistake:** Using `file()` for generated files.
  - **Fix:** Terraform functions read files that exist before the run starts.
- **Mistake:** Masking errors with broad `try`.
  - **Fix:** Validate inputs and fail loudly for bad configuration.
- **Mistake:** Assuming functions can call AWS APIs.
  - **Fix:** Functions are local expression helpers; providers call APIs.

---

## 10. Dependencies

### Concept

Terraform dependencies define ordering. Most dependencies are implicit through references. Explicit dependencies use `depends_on`.

Implicit dependency:

```hcl
resource "aws_instance" "web" {
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

Explicit dependency:

```hcl
resource "aws_instance" "web" {
  depends_on = [aws_security_group_rule.http]
}
```

### Why it exists

AWS resources frequently require other resources to exist first. Terraform needs to know safe order and which operations can run in parallel.

### Real-world use cases

- EC2 depends on security groups and subnets.
- EIP association depends on an instance.
- Route records depend on load balancer DNS names.
- IAM policy attachments depend on roles and policies.

### ASCII diagram

```text
aws_security_group.web
          |
          v
aws_instance.web
          |
          v
aws_eip.web
```

### Step-by-step example

```hcl
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"
}
```

The reference to `aws_instance.web.id` creates a dependency. Terraform will create the instance before associating the Elastic IP.

### Production best practices

- Prefer implicit dependencies.
- Use `depends_on` only for hidden dependencies, such as a service needing an IAM policy attachment before startup.
- Avoid dependency cycles.
- Keep graph boundaries simple by splitting large systems into modules/stacks.

### Common mistakes and troubleshooting

- **Mistake:** Adding `depends_on` everywhere.
  - **Fix:** Let references create the graph.
- **Mistake:** Depending on outputs from unrelated modules unnecessarily.
  - **Fix:** Pass only what is needed.
- **Mistake:** Circular dependencies between resources.
  - **Fix:** Reconsider ownership and split resources.

---

## 11. Resource References

### Concept

Resource references access attributes from resources, data sources, variables, locals, and modules.

```hcl
aws_instance.web.id
var.instance_type
local.name_prefix
data.aws_ami.amazon_linux_2023.id
module.network.vpc_id
```

### Why it exists

References connect infrastructure. They also create dependency graph edges when one managed object uses another object's attribute.

### Real-world use cases

- Pass security group IDs to EC2.
- Use an AMI ID from a data source.
- Output a public IP.
- Attach IAM policies to role names.
- Build DNS records from load balancer outputs.

### ASCII diagram

```text
data.aws_ami.amazon_linux_2023.id ---> aws_instance.web.ami
aws_security_group.web.id ---------> aws_instance.web.vpc_security_group_ids
aws_instance.web.public_ip --------> output.public_ip
```

### Step-by-step example

```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
}

output "web_instance_id" {
  value = aws_instance.web.id
}
```

### Production best practices

- Reference IDs and ARNs instead of duplicating strings.
- Output only stable API values that other systems need.
- Use data sources for external objects that Terraform does not manage.
- Keep resource names meaningful so references read like documentation.

### Common mistakes and troubleshooting

- **Mistake:** Copying an ID from AWS instead of referencing a resource.
  - **Fix:** Use `aws_security_group.web.id` or a data source.
- **Mistake:** Referencing a resource created with `count` without an index.
  - **Fix:** Use `aws_instance.web[0].id` or for expressions.
- **Mistake:** Referencing an attribute that does not exist.
  - **Fix:** Check provider docs or `terraform console`.

---

## Hands-on exercises

1. **Variable validation**
   - Add validation to an SSH CIDR variable.
   - Test with a valid `/32` and an invalid string.

2. **Outputs as APIs**
   - Add outputs for instance ID, public IP, and web URL.
   - Decide which outputs would be safe for downstream automation.

3. **Locals and tags**
   - Add a `local.common_tags` map.
   - Merge it into every resource-specific tag map.

See `exercises/README.md` for hints.

---

## Project: Simple web server environment

The project in `project/` creates a VPC-light environment:

- Default VPC lookup.
- Security group for HTTP and optional SSH.
- Amazon Linux 2023 EC2 instance with nginx installed through `user_data`.
- Elastic IP associated to the instance.
- Outputs for public IP, DNS name, and URL.

Run it:

```bash
cd modules/02-terraform-basics/project
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Destroy it when finished:

```bash
terraform destroy
```

---

## Advanced topics to explore after this module

- Remote backends and state locking.
- `terraform import` for existing resources.
- `moved` blocks for safe refactoring.
- Input variable object types for environment configuration.
- Provider aliases for multiple AWS regions.
- Reusable modules for EC2 and security groups.

---

## Interview prep Q&A

### 1. What does `terraform init` do?

It initializes the working directory, downloads provider plugins, configures the backend, and prepares Terraform to run plans and applies.

### 2. What is the purpose of `terraform validate`?

It checks whether the configuration is syntactically valid and internally consistent with provider schemas. It does not guarantee AWS permissions or remote API success.

### 3. Why should variables have types?

Types catch bad inputs early, document expected shape, and make expressions more predictable.

### 4. What is the difference between a variable and a local?

A variable is an input controlled by callers. A local is an internal derived value used to simplify configuration.

### 5. What are outputs used for?

Outputs expose selected values after apply for humans, automation, or downstream Terraform stacks.

### 6. How do implicit dependencies work?

When one resource references another resource's attribute, Terraform creates a dependency edge and orders operations accordingly.

### 7. When would you use `depends_on`?

Use it when a real dependency exists but Terraform cannot infer it through attribute references.

### 8. Why is renaming a resource block risky?

The Terraform address changes. Without a `moved` block or state move, Terraform may plan to destroy the old address and create a new resource.

### 9. What is `.terraform.lock.hcl`?

It records selected provider versions and checksums. Commit it so provider installation is repeatable across machines and CI.

### 10. Why are data sources different from resources?

Resources manage objects. Data sources read existing objects managed elsewhere or selected dynamically, such as the latest Amazon Linux AMI.

---

## Real-world case study: Standardizing small service environments

A backend team had several internal services running on hand-created EC2 instances. Every service needed a security group, an instance, a static IP for an allowlist, and standard tags. Engineers copied old Terraform snippets and edited them by hand, causing inconsistent naming and missing tags.

The team introduced a small root module pattern:

- Variables for `project_name`, `environment`, `allowed_ssh_cidr`, and `instance_type`.
- Locals for normalized names and common tags.
- A data source for the latest Amazon Linux AMI.
- An EC2 resource referencing a security group.
- An Elastic IP resource referencing the EC2 instance.
- Outputs for `web_url`, `public_ip`, and `instance_id`.

### Results

- New service environments were created consistently.
- Security group reviews became easy because rules were declared in code.
- Elastic IPs were visible in Terraform output for allowlist updates.
- Tag consistency improved cost allocation.
- Engineers learned to review `plan` output before making infrastructure changes.

The key lesson: basic Terraform constructs are enough to create useful production workflows when they are typed, reviewed, and kept simple.
