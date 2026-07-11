# Module 3 - Intermediate Terraform

This module moves from basic single-resource configurations to patterns you will use in production: data sources, conditionals, `count`, `for_each`, dynamic blocks, lifecycle rules, `depends_on`, meta-arguments, and sensitive values.

The project deploys a small multi-server application in `us-east-1` using a server map, dynamic ingress rules, conditional resource creation, and sensitive outputs.

---

## 1. Data Sources

### Concept

Data sources read information from providers without managing the remote object. They let Terraform use existing infrastructure or dynamically selected values.

```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
```

### Why it exists

Not every object Terraform uses should be created by the current configuration. Production stacks frequently need to read:

- Existing VPCs and subnets.
- Latest approved AMIs.
- Current AWS account identity.
- Existing Route 53 zones.
- Secrets or parameters created by another system.

### Real-world use cases

- Selecting the latest Amazon Linux 2023 AMI.
- Deploying into a platform-managed VPC.
- Reading the current AWS account ID for ARN construction.
- Looking up an ACM certificate by domain.

### ASCII diagram

```text
Terraform config
      |
      v
data.aws_ami.amazon_linux_2023 ----read----> AWS EC2 DescribeImages
      |
      v
aws_instance.web.ami
```

### Step-by-step example

```hcl
data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

output "account_and_vpc" {
  value = {
    account_id = data.aws_caller_identity.current.account_id
    vpc_id     = data.aws_vpc.default.id
  }
}
```

Run `terraform plan`; no resources are created, but Terraform reads AWS APIs.

### Production best practices

- Use filters specific enough to avoid accidental matches.
- Prefer approved AMI pipelines for production instead of unconstrained "latest" images.
- Treat data source lookups as dependencies on external ownership.
- Output or log selected IDs during learning so surprises are visible.

### Common mistakes and troubleshooting

- **Mistake:** Data source returns multiple matches.
  - **Fix:** Add more filters or use a deterministic selection.
- **Mistake:** Data source returns no matches.
  - **Fix:** Confirm region, owner, tags, and naming pattern.
- **Mistake:** Treating data sources as managed resources.
  - **Fix:** Data sources read; resources create/update/delete.

---

## 2. Conditionals

### Concept

Conditionals choose between two values:

```hcl
condition ? true_value : false_value
```

Example:

```hcl
instance_type = var.environment == "prod" ? "t3.small" : "t3.micro"
```

### Why it exists

Infrastructure often needs controlled differences between environments without duplicating the whole configuration.

### Real-world use cases

- Enable backups only in production.
- Use larger instance types for production.
- Choose private or public networking.
- Create optional resources in labs.

### ASCII diagram

```text
var.create_elastic_ips
       |
       v
true ----------> create EIPs
false ---------> skip EIPs
```

### Step-by-step example

```hcl
variable "create_elastic_ip" {
  type    = bool
  default = false
}

resource "aws_eip" "web" {
  count = var.create_elastic_ip ? 1 : 0

  domain = "vpc"
}
```

Reference carefully:

```hcl
output "elastic_ip" {
  value = var.create_elastic_ip ? aws_eip.web[0].public_ip : null
}
```

### Production best practices

- Keep conditionals simple and obvious.
- Prefer separate environment values over deeply nested conditionals.
- Be careful when a conditional changes resource count; it may create or destroy resources.
- Validate feature flag combinations.

### Common mistakes and troubleshooting

- **Mistake:** Returning different types from each branch.
  - **Fix:** Both branches should have compatible types.
- **Mistake:** Referencing `aws_eip.web[0]` when count is zero.
  - **Fix:** Guard references with the same condition.
- **Mistake:** Hiding major production differences behind a small boolean.
  - **Fix:** Make high-risk differences explicit and reviewed.

---

## 3. `count`

### Concept

`count` creates multiple instances of a resource from a number. Terraform addresses instances by numeric index.

```hcl
resource "aws_instance" "worker" {
  count = 3

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  tags = {
    Name = "worker-${count.index}"
  }
}
```

### Why it exists

Some infrastructure is naturally repeated by quantity. `count` is simple for identical resources.

### Real-world use cases

- Create three identical test instances.
- Enable or disable one optional resource with `count = condition ? 1 : 0`.
- Create a fixed number of subnets in a lab.

### ASCII diagram

```text
count = 3

aws_instance.worker[0]
aws_instance.worker[1]
aws_instance.worker[2]
```

### Step-by-step example

```hcl
variable "worker_count" {
  type    = number
  default = 2
}

resource "aws_instance" "worker" {
  count = var.worker_count

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
}
```

### Production best practices

- Use `count` for truly identical resources.
- Avoid `count` when each instance has a stable identity or different settings.
- Be careful when reordering lists used with `count`; indexes can shift.
- Prefer `for_each` for named objects.

### Common mistakes and troubleshooting

- **Mistake:** Removing an item from the middle of a counted list.
  - **Result:** Terraform may replace resources because indexes shift.
  - **Fix:** Use `for_each` with stable keys.
- **Mistake:** Forgetting to index counted resources.
  - **Fix:** Use `aws_instance.worker[0].id` or a for expression.
- **Mistake:** Using count for long-lived production servers with names.
  - **Fix:** Use `for_each`.

---

## 4. `for_each`

### Concept

`for_each` creates resource instances from a map or set. Instances are addressed by stable keys.

```hcl
resource "aws_instance" "server" {
  for_each = var.servers

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = each.value.instance_type

  tags = {
    Name = each.key
  }
}
```

### Why it exists

Production infrastructure often has named resources with different settings. Stable keys reduce accidental replacement when you add or remove items.

### Real-world use cases

- Multiple application servers by role.
- Security group rules by name.
- IAM users or roles from a map.
- S3 buckets by purpose.

### ASCII diagram

```text
var.servers = {
  web-a = {...}
  web-b = {...}
}

aws_instance.server["web-a"]
aws_instance.server["web-b"]
```

### Step-by-step example

```hcl
variable "servers" {
  type = map(object({
    instance_type = string
  }))
}

resource "aws_instance" "server" {
  for_each = var.servers

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = each.value.instance_type
}
```

Add a new server by adding a new map key; existing keys remain stable.

### Production best practices

- Use meaningful, stable keys.
- Never use values that change often as keys.
- Prefer maps of objects for named infrastructure.
- Use outputs that preserve keys, such as `{ for name, instance in aws_instance.server : name => instance.id }`.

### Common mistakes and troubleshooting

- **Mistake:** Changing a `for_each` key casually.
  - **Result:** Terraform sees delete old key and create new key.
  - **Fix:** Use a `moved` block or `terraform state mv` for intentional renames.
- **Mistake:** Using a list directly with `for_each`.
  - **Fix:** Convert to `toset(...)` only when identity by value is acceptable.
- **Mistake:** Making keys from computed provider attributes.
  - **Fix:** `for_each` keys must be known during planning.

---

## 5. Dynamic Blocks

### Concept

Dynamic blocks generate repeated nested blocks from collections. They are useful when a provider resource uses nested blocks rather than separate resources.

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules

  content {
    from_port   = ingress.value.from_port
    to_port     = ingress.value.to_port
    protocol    = ingress.value.protocol
    cidr_blocks = ingress.value.cidr_blocks
  }
}
```

### Why it exists

Some provider schemas require nested blocks. Dynamic blocks avoid copy-pasting many similar nested blocks while keeping the parent resource readable.

### Real-world use cases

- Security group ingress rules.
- Load balancer listener actions.
- Auto Scaling Group tag blocks.
- CloudFront origin blocks.

### ASCII diagram

```text
var.ingress_rules map
       |
       v
dynamic "ingress"
       |
       v
ingress { port 80 }
ingress { port 443 }
```

### Step-by-step example

```hcl
variable "ingress_rules" {
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group" "app" {
  name   = "app"
  vpc_id = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      description = ingress.key
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

### Production best practices

- Use dynamic blocks when repetition is meaningful and controlled.
- Keep input object types strict.
- Prefer separate resources when lifecycle of each nested item needs independent management.
- Avoid dynamic blocks that hide important security behavior.

### Common mistakes and troubleshooting

- **Mistake:** Using dynamic blocks for top-level resources.
  - **Fix:** Use `for_each` on the resource itself.
- **Mistake:** Making dynamic content too abstract to review.
  - **Fix:** Keep rule names and values clear.
- **Mistake:** Expecting dynamic blocks to work for arguments.
  - **Fix:** Dynamic blocks generate nested blocks, not simple arguments.

---

## 6. Lifecycle Rules

### Concept

The `lifecycle` block changes how Terraform handles resource changes.

Common lifecycle arguments:

- `prevent_destroy`
- `create_before_destroy`
- `ignore_changes`
- `replace_triggered_by`

```hcl
resource "aws_s3_bucket" "critical" {
  bucket = "my-critical-bucket"

  lifecycle {
    prevent_destroy = true
  }
}
```

### Why it exists

Some resources are risky to replace or destroy. Lifecycle rules add guardrails where the default behavior is too dangerous or not suitable for uptime.

### Real-world use cases

- Prevent accidental destruction of production databases or buckets.
- Create replacement load balancer target groups before destroying old ones.
- Ignore externally managed tags.
- Force replacement when a related artifact changes.

### ASCII diagram

```text
Terraform plan wants destroy
          |
          v
lifecycle.prevent_destroy
          |
          v
plan fails with safety error
```

### Step-by-step example

```hcl
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  lifecycle {
    create_before_destroy = true
  }
}
```

For a critical bucket:

```hcl
# lifecycle {
#   prevent_destroy = true
# }
```

The project includes a commented example so students see the pattern without blocking lab cleanup.

### Production best practices

- Use `prevent_destroy` for critical stateful resources.
- Document why `ignore_changes` exists.
- Avoid using `ignore_changes` to hide drift you should fix.
- Test lifecycle behavior in lower environments.

### Common mistakes and troubleshooting

- **Mistake:** Enabling `prevent_destroy` in a lab and forgetting it.
  - **Fix:** Remove or comment it before `terraform destroy`.
- **Mistake:** Ignoring important changes forever.
  - **Fix:** Periodically review every `ignore_changes`.
- **Mistake:** Assuming `create_before_destroy` is always possible.
  - **Fix:** Names and quotas may prevent duplicate resources.

---

## 7. `depends_on`

### Concept

`depends_on` adds an explicit dependency when Terraform cannot infer ordering through references.

```hcl
resource "aws_instance" "app" {
  depends_on = [aws_iam_role_policy_attachment.app]

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
}
```

### Why it exists

Most dependencies should be implicit. Explicit dependencies are for real relationships invisible to Terraform, such as an application requiring a policy attachment before bootstrapping.

### Real-world use cases

- Ensure IAM permissions are attached before an instance starts.
- Ensure logging buckets/policies exist before creating a service that writes logs.
- Order resources when the provider API has eventual consistency edge cases.

### ASCII diagram

```text
aws_iam_role_policy_attachment.app
              |
              v
        aws_instance.app

No attribute reference is needed by EC2, but the boot script needs the permission.
```

### Step-by-step example

```hcl
resource "null_resource" "schema_ready" {
  triggers = {
    migration_version = var.migration_version
  }
}

resource "aws_instance" "app" {
  depends_on = [null_resource.schema_ready]

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
}
```

This example is illustrative; avoid `null_resource` when a provider-native resource exists.

### Production best practices

- Prefer references over `depends_on`.
- Add comments for non-obvious explicit dependencies.
- Avoid module-level `depends_on` unless necessary; it can over-constrain graphs.
- Revisit explicit dependencies after refactors.

### Common mistakes and troubleshooting

- **Mistake:** Using `depends_on` to fix unknown values.
  - **Fix:** Dependencies control order, not value availability during plan.
- **Mistake:** Depending on entire modules unnecessarily.
  - **Fix:** Depend on specific resources or outputs when possible.
- **Mistake:** Adding `depends_on` for line-order expectations.
  - **Fix:** Terraform does not use file order.

---

## 8. Meta-arguments

### Concept

Meta-arguments are special arguments Terraform understands across resource types. Common meta-arguments:

- `count`
- `for_each`
- `depends_on`
- `provider`
- `lifecycle`

Example:

```hcl
resource "aws_instance" "server" {
  for_each = var.servers

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = each.value.instance_type
}
```

### Why it exists

Meta-arguments control Terraform behavior instead of provider-specific resource settings.

### Real-world use cases

- Create one resource per map entry with `for_each`.
- Select an aliased provider for another region.
- Guard critical resources with `lifecycle`.
- Model hidden ordering with `depends_on`.

### ASCII diagram

```text
Terraform meta-argument layer
  count / for_each / depends_on / lifecycle / provider
                 |
                 v
Provider resource arguments
  ami / instance_type / tags / vpc_id
```

### Step-by-step example

Provider alias:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "west_logs" {
  provider = aws.west
  bucket   = "my-west-logs-12345"
}
```

### Production best practices

- Understand whether an argument is Terraform-level or provider-level.
- Use provider aliases for multi-region or multi-account deployments.
- Prefer `for_each` over `count` for named resources.
- Treat lifecycle rules as operational policy.

### Common mistakes and troubleshooting

- **Mistake:** Trying to compute provider aliases dynamically.
  - **Fix:** Provider selections must be statically understandable.
- **Mistake:** Mixing `count` and `for_each` on the same resource.
  - **Fix:** Use one repetition strategy.
- **Mistake:** Forgetting key/index references for repeated resources.
  - **Fix:** Use `resource.name["key"]` for `for_each` and `resource.name[0]` for `count`.

---

## 9. Sensitive Values

### Concept

Terraform can mark variables and outputs as sensitive. Sensitive values are hidden in CLI output, but they may still be stored in state.

```hcl
variable "admin_password" {
  type      = string
  sensitive = true
}

output "admin_password" {
  value     = var.admin_password
  sensitive = true
}
```

### Why it exists

Plans and outputs are often visible in terminals, CI logs, or pull request comments. Sensitive marking reduces accidental exposure.

### Real-world use cases

- Database passwords.
- API tokens.
- Initial admin passwords.
- Private keys.
- Secret ARNs where even the name may reveal sensitive context.

### ASCII diagram

```text
terraform apply output:

admin_password = <sensitive>

state file:

admin_password may still be present
```

### Step-by-step example

```hcl
variable "admin_password" {
  description = "Demo password for the application."
  type        = string
  sensitive   = true
}

output "admin_password_warning" {
  value     = var.admin_password
  sensitive = true
}
```

Read sensitive output intentionally:

```bash
terraform output -raw admin_password_warning
```

### Production best practices

- Prefer secret managers over raw secret variables.
- Do not commit secret values in `.tfvars`.
- Restrict access to state.
- Mark sensitive variables and outputs.
- Avoid passing secrets through `user_data`; cloud-init logs can expose them.

### Common mistakes and troubleshooting

- **Mistake:** Believing sensitive values are encrypted by Terraform.
  - **Fix:** Sensitive only affects display; protect state with backend encryption and IAM.
- **Mistake:** Printing secrets in `user_data`.
  - **Fix:** Fetch secrets at runtime from AWS Secrets Manager or SSM Parameter Store with IAM.
- **Mistake:** Outputting a secret because it is convenient.
  - **Fix:** Output references to secret storage instead.

---

## Hands-on exercises

1. **Convert count to for_each**
   - Start with two counted instances.
   - Convert them to a `servers` map.
   - Predict which addresses will change.

2. **Add a dynamic HTTPS ingress rule**
   - Add port 443 to `ingress_rules`.
   - Plan and verify the dynamic nested block.

3. **Protect a critical resource**
   - Add a demo S3 bucket.
   - Temporarily enable `prevent_destroy`.
   - Observe how Terraform blocks destruction.

See `exercises/README.md` for hints.

---

## Project: Deploy a multi-server application

The project in `project/` demonstrates:

- Latest Amazon Linux 2023 AMI data source.
- `for_each` over a server map.
- Conditional Elastic IP creation.
- Dynamic security group ingress rules.
- Sensitive variable and output.
- Commented `prevent_destroy` lifecycle example.

Run it:

```bash
cd modules/03-intermediate/project
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Destroy it:

```bash
terraform destroy
```

---

## Advanced topics to explore after this module

- `moved` blocks when changing addresses from `count` to `for_each`.
- Optional object attributes and defaults.
- Module design with object inputs.
- Secret retrieval from AWS Secrets Manager or SSM Parameter Store.
- Blue/green deployment patterns with lifecycle rules.
- Policy checks for dangerous security group rules.

---

## Interview prep Q&A

### 1. When should you use a data source?

Use a data source when Terraform needs to read an existing or dynamically selected object that this configuration does not manage, such as an existing VPC or latest AMI.

### 2. What is the main risk of `count`?

`count` uses numeric indexes. If list ordering changes or an item is removed from the middle, Terraform may replace resources unexpectedly.

### 3. Why is `for_each` often better for production resources?

`for_each` uses stable keys, so adding or removing one named item does not shift indexes for other resources.

### 4. What are dynamic blocks for?

Dynamic blocks generate repeated nested blocks inside a resource. They are not used to create top-level resources.

### 5. What does `prevent_destroy` do?

It causes Terraform to fail a plan that would destroy the resource, adding a safety guard for critical infrastructure.

### 6. Does `depends_on` make unknown values known during plan?

No. `depends_on` controls operation ordering. It does not make provider-computed values available before apply.

### 7. What are Terraform meta-arguments?

They are Terraform-level arguments such as `count`, `for_each`, `depends_on`, `provider`, and `lifecycle` that control resource behavior across providers.

### 8. Are sensitive Terraform values stored in state?

They can be. `sensitive = true` hides values from CLI output, but state must still be protected with encryption and access controls.

### 9. How do you safely rename a `for_each` key?

Use a `moved` block or `terraform state mv` so Terraform understands the address changed without destroying and recreating the object.

### 10. When is `ignore_changes` appropriate?

Use it when another trusted system legitimately manages an attribute, such as organization-wide tags. Do not use it to hide unmanaged drift.

---

## Real-world case study: Scaling a single-server app to named application nodes

A team started with one EC2 instance for an internal API. As traffic grew, they added background workers and a second web node. Their first Terraform attempt used `count = 3` and a list of instance types.

Problems appeared quickly:

- Removing the first list item caused Terraform to want to replace later instances.
- Security group rules were copied manually and drifted.
- An admin password variable appeared in CI logs.
- A production bucket was nearly destroyed during cleanup.

The team refactored:

- Replaced `count` with `for_each` using keys `web-a`, `web-b`, and `worker-a`.
- Moved ingress rules into a typed `ingress_rules` map rendered with a dynamic block.
- Marked password variables and outputs as sensitive.
- Added `prevent_destroy` to critical stateful resources.
- Used data sources for the platform VPC and approved AMI.

### Result

- Adding `worker-b` created only one new instance.
- Security group changes were reviewed as data changes.
- Sensitive values disappeared from normal CLI output.
- Cleanup workflows stopped at protected resources instead of deleting them.

The key lesson: intermediate Terraform features are not clever syntax tricks. They are tools for preserving resource identity, reducing copy-paste, and adding operational safety.
