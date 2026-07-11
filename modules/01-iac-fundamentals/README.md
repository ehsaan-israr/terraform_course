# Module 1 - Infrastructure as Code Fundamentals

This module teaches the mental model behind Infrastructure as Code (IaC) and Terraform. You already know AWS, Linux, Docker, and backend engineering; the goal is to connect those skills to reproducible infrastructure workflows that work in production teams.

By the end you should be able to explain what Terraform does, why state matters, how Terraform decides execution order, and how to safely run `init`, `plan`, `apply`, and `destroy` against AWS.

> Region used throughout this course: `us-east-1`.

---

## 1. What is Infrastructure as Code?

### Concept

Infrastructure as Code means describing infrastructure in version-controlled files instead of creating it manually in a console or with one-off shell commands.

For example, instead of clicking through the AWS Console to create an S3 bucket, you write:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "my-company-prod-logs-12345"

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

Terraform reads this configuration, compares it with known infrastructure state, and calls AWS APIs to create or update resources.

### Why it exists

Manual infrastructure does not scale well:

- Nobody remembers every console click six months later.
- Environments drift because dev, staging, and prod are created slightly differently.
- Reviews are impossible when changes happen through a UI.
- Disaster recovery becomes slow because infrastructure must be rediscovered.
- Security controls are easy to forget under pressure.

IaC turns infrastructure into an engineering artifact:

- Reviewed through pull requests.
- Tested with validation and policy checks.
- Reused across environments.
- Audited through Git history.
- Rebuilt after incidents.

### Real-world use cases

- Creating repeatable development, staging, and production AWS accounts.
- Provisioning VPCs, subnets, security groups, databases, queues, and compute.
- Recreating ephemeral test environments for every pull request.
- Standardizing tags, encryption, logging, and backup settings.
- Disaster recovery in a second region.

### ASCII diagram

```text
Manual infrastructure:

Engineer -> AWS Console clicks -> AWS resources
              |
              v
        tribal knowledge

Infrastructure as Code:

Engineer -> Git commit -> Review -> Terraform -> AWS APIs -> AWS resources
              |                         |
              v                         v
          audit trail              state + plan
```

### Step-by-step example

1. Create a Terraform file named `main.tf`.
2. Declare an AWS provider.
3. Define an S3 bucket.
4. Run `terraform init`.
5. Run `terraform plan`.
6. Review the proposed actions.
7. Run `terraform apply`.
8. Commit the configuration, not the generated local state.

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "replace-me-with-a-globally-unique-name"

  tags = {
    Name      = "iac-example"
    ManagedBy = "terraform"
  }
}
```

### Production best practices

- Store Terraform code in Git.
- Use pull requests for infrastructure changes.
- Use a remote backend for state in team environments.
- Protect production applies behind review and CI/CD gates.
- Use consistent naming and tags.
- Split infrastructure into sensible stacks, such as network, data, and application.
- Prefer small, reviewable changes over huge infrastructure rewrites.

### Common mistakes and troubleshooting

- **Mistake:** Creating resources manually after Terraform manages the same area.
  - **Result:** Drift between code and reality.
  - **Fix:** Import existing resources or update Terraform code.
- **Mistake:** Committing `terraform.tfstate`.
  - **Result:** Secrets and resource metadata can leak.
  - **Fix:** Add state files to `.gitignore`; use remote state for teams.
- **Mistake:** Skipping `terraform plan`.
  - **Result:** Unexpected deletes or replacements.
  - **Fix:** Always review plans before apply, especially in shared environments.

---

## 2. Imperative vs Declarative Infrastructure

### Concept

An imperative tool describes **how** to do something step by step. A declarative tool describes **what final state** should exist.

Imperative example:

```bash
aws s3api create-bucket --bucket my-app-assets-12345 --region us-east-1
aws s3api put-bucket-versioning \
  --bucket my-app-assets-12345 \
  --versioning-configuration Status=Enabled
```

Declarative Terraform example:

```hcl
resource "aws_s3_bucket" "assets" {
  bucket = "my-app-assets-12345"
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

Terraform decides which AWS API calls are needed to make reality match the configuration.

### Why it exists

Backend engineers often write scripts to automate operations. Scripts are useful, but they can become difficult to rerun safely:

- What happens if step 3 succeeds and step 4 fails?
- Can the script be run twice without creating duplicates?
- How does the script know if someone changed the resource manually?
- How does the script preview destructive changes?

Declarative IaC handles these concerns by comparing desired configuration with state and remote infrastructure.

### Real-world use cases

- Maintaining long-lived infrastructure such as VPCs and databases.
- Safely evolving production infrastructure over months or years.
- Recreating consistent lower environments.
- Reviewing infrastructure changes before they happen.

### ASCII diagram

```text
Imperative:

start
  |
  v
create VPC -> create subnet -> create SG -> create EC2
  |
  v
hope every previous step is still true

Declarative:

desired configuration + state + provider reads
             |
             v
        Terraform plan
             |
             v
     minimal actions to converge
```

### Step-by-step example

Suppose your desired state is "one EC2 instance exists."

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}
```

Terraform behavior:

1. If no instance exists in state, Terraform plans `create`.
2. If the instance exists and matches config, Terraform plans no changes.
3. If `instance_type` changes, Terraform plans an update or replacement depending on AWS rules.
4. If the resource block is removed, Terraform plans destroy.

### Production best practices

- Think in desired outcomes, not procedural steps.
- Make resources explicit and readable.
- Avoid using `local-exec` provisioners for normal infrastructure operations.
- Keep bootstrap scripts small; use image baking or configuration management for complex host setup.
- Treat `terraform plan` as a production change document.

### Common mistakes and troubleshooting

- **Mistake:** Translating every shell command into Terraform provisioners.
  - **Fix:** Use provider resources whenever possible.
- **Mistake:** Expecting Terraform to manage resources not declared or imported.
  - **Fix:** Terraform only manages resources in configuration and state.
- **Mistake:** Relying on resource creation order in file order.
  - **Fix:** Terraform uses dependency graph edges, not line order.

---

## 3. Why Terraform?

### Concept

Terraform is an open-source IaC tool that uses HashiCorp Configuration Language (HCL) to manage infrastructure through providers. It is declarative, provider-based, stateful, and plan-driven.

Core workflow:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### Why it exists

Terraform provides a common workflow across many infrastructure APIs:

- AWS resources through the AWS provider.
- Kubernetes resources through the Kubernetes provider.
- DNS through providers such as Route 53 or Cloudflare.
- SaaS systems through providers for Datadog, GitHub, PagerDuty, and more.

For production teams, the most important feature is the plan/apply workflow. Terraform can show intended changes before making them.

### Real-world use cases

- Provisioning AWS platforms for applications.
- Managing networking, IAM, compute, databases, and observability resources.
- Building golden infrastructure modules for product teams.
- Creating repeatable environments for CI, demos, and performance tests.

### ASCII diagram

```text
Terraform code
   |
   v
terraform plan ----> human/code review
   |
   v
terraform apply
   |
   v
provider plugin
   |
   v
AWS APIs
```

### Step-by-step example

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "my-app-${var.environment}-artifacts-12345"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}
```

Run:

```bash
terraform init
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

### Production best practices

- Pin provider versions with a version constraint such as `~> 5.0`.
- Commit `.terraform.lock.hcl` after initialization in real repositories.
- Run `terraform fmt` and `terraform validate` in CI.
- Use separate state per environment.
- Prefer modules for repeated infrastructure patterns.
- Keep provider credentials outside source code.

### Common mistakes and troubleshooting

- **Mistake:** Not pinning provider versions.
  - **Result:** A future provider release may change behavior.
  - **Fix:** Use `required_providers` with version constraints.
- **Mistake:** Using one giant state file for everything.
  - **Result:** Slow plans and high blast radius.
  - **Fix:** Split stacks by lifecycle and ownership.
- **Mistake:** Running Terraform from a laptop with unclear credentials.
  - **Fix:** Use named AWS profiles, SSO, or CI roles with least privilege.

---

## 4. Terraform Architecture

### Concept

Terraform is a CLI that loads configuration, installs provider plugins, reads state, builds a dependency graph, creates a plan, and executes provider API calls.

Important pieces:

- **Configuration:** `.tf` files written in HCL.
- **CLI:** `terraform` binary.
- **Provider plugins:** Separate executables that understand APIs such as AWS.
- **State:** Terraform's mapping of resource addresses to real remote objects.
- **Backend:** Where state is stored.
- **Dependency graph:** The execution model for resource ordering.

### Why it exists

Terraform separates the generic workflow from cloud-specific APIs. The Terraform core does not need to know how to create an EC2 instance. It asks the AWS provider to do that.

### ASCII diagram

```text
                +---------------------+
                | Terraform CLI/Core  |
                +----------+----------+
                           |
        +------------------+------------------+
        |                  |                  |
        v                  v                  v
 configuration        state backend      provider plugins
   .tf files          local/S3/etc.       aws/random/etc.
                                                |
                                                v
                                           remote APIs
```

### Step-by-step example

When you run `terraform apply`:

1. Terraform reads all `.tf` files in the current directory.
2. It loads input variables.
3. It initializes providers if needed.
4. It reads current state.
5. It asks providers to refresh remote resource information.
6. It builds a graph of dependencies.
7. It calculates create, update, replace, or destroy actions.
8. It asks for approval unless `-auto-approve` is used.
9. It executes graph operations.
10. It writes updated state.

### Terraform/HCL code

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Course    = "aws-terraform-production-engineering"
    }
  }
}
```

### Production best practices

- Keep provider configuration boring and explicit.
- Use `default_tags` to enforce baseline tags.
- Use remote state with locking for shared environments.
- Make state boundaries match team ownership and deployment frequency.
- Run Terraform from automation for production changes when possible.

### Common mistakes and troubleshooting

- **Mistake:** Assuming Terraform reads files in a specific order.
  - **Fix:** File order is irrelevant; dependencies determine order.
- **Mistake:** Configuring provider credentials in `.tf` files.
  - **Fix:** Use environment variables, AWS profiles, SSO, or instance/CI roles.
- **Mistake:** Mixing unrelated providers and systems in one stack.
  - **Fix:** Keep stacks focused and independently deployable.

---

## 5. Providers

### Concept

Providers are Terraform plugins that translate Terraform resource definitions into API calls. The AWS provider knows how to create EC2 instances, S3 buckets, security groups, IAM roles, and thousands of other AWS resources.

### Why it exists

Terraform core needs a stable way to work with many APIs. Providers own API-specific logic:

- Authentication.
- CRUD operations.
- Schema validation.
- Diff behavior.
- Import behavior.

### Real-world use cases

- AWS provider for infrastructure.
- Random provider for generated suffixes.
- TLS provider for keys and certificates.
- Kubernetes provider for cluster resources after EKS exists.
- Cloudflare provider for DNS records pointing to AWS load balancers.

### ASCII diagram

```text
resource "aws_instance" "web"
          |
          v
   AWS provider schema
          |
          v
   EC2 RunInstances API
          |
          v
    i-0123456789abcdef0
```

### Step-by-step example

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
```

Run:

```bash
terraform init
terraform plan
```

Terraform downloads the AWS provider and uses your AWS credentials to read the account identity.

### Production best practices

- Pin provider source and version.
- Commit the provider lock file after `terraform init`.
- Upgrade providers deliberately in dedicated pull requests.
- Read provider upgrade guides before major upgrades.
- Use provider aliases when managing multiple regions or accounts.

### Common mistakes and troubleshooting

- **Mistake:** `NoCredentialProviders` or `could not find valid credential sources`.
  - **Fix:** Confirm `aws sts get-caller-identity` works in the same shell.
- **Mistake:** Provider version conflicts across modules.
  - **Fix:** Align version constraints and run `terraform init -upgrade` when intentionally upgrading.
- **Mistake:** Creating resources in the wrong region.
  - **Fix:** Set `region` explicitly and output the active region/account during early learning.

---

## 6. Resource Graph

### Concept

Terraform builds a dependency graph from references between resources and data sources. It uses that graph to decide safe creation, update, and deletion order.

If an EC2 instance references a security group ID, Terraform knows the security group must exist before the instance is created.

```hcl
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_instance" "web" {
  ami                    = "ami-0abcdef1234567890"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

### Why it exists

Infrastructure resources are connected:

- Instances need subnets and security groups.
- Load balancer listeners need load balancers and target groups.
- IAM policy attachments need roles and policies.
- DNS records need load balancer names.

The graph lets Terraform parallelize independent work while respecting dependencies.

### ASCII diagram

```text
data.aws_vpc.default
        |
        v
aws_security_group.web
        |
        v
aws_instance.web
        |
        v
output.public_ip
```

### Step-by-step example

1. Write a data source for the default VPC.
2. Create a security group in that VPC.
3. Reference the security group from an EC2 instance.
4. Output the EC2 public IP.

Terraform sees references and creates graph edges automatically.

### Production best practices

- Prefer implicit dependencies through references.
- Use `depends_on` only when a dependency is real but invisible to Terraform.
- Avoid unnecessary dependencies that serialize otherwise independent operations.
- Use `terraform graph` for advanced troubleshooting.
- Keep dependency chains understandable; deeply tangled stacks are harder to operate.

### Common mistakes and troubleshooting

- **Mistake:** Expecting line order to control creation.
  - **Fix:** Use references.
- **Mistake:** Overusing `depends_on`.
  - **Result:** Slower plans and hidden design problems.
  - **Fix:** Model dependencies through attributes whenever possible.
- **Mistake:** Circular dependencies.
  - **Result:** Terraform cannot build a valid graph.
  - **Fix:** Split resources or break the cycle with separate resources.

---

## 7. State File

### Concept

Terraform state records the mapping between Terraform resource addresses and real infrastructure objects.

Example resource address:

```text
aws_instance.web
```

Example remote object:

```text
i-0123456789abcdef0
```

Terraform needs state to know that `aws_instance.web` in code corresponds to that specific EC2 instance in AWS.

### Why it exists

AWS APIs can list infrastructure, but they do not know your Terraform names, module structure, or intent. State is Terraform's source of truth for ownership and mapping.

State also stores computed attributes, such as:

- EC2 instance IDs.
- Public IPs.
- ARNs.
- Security group IDs.
- Some sensitive values returned by providers.

### ASCII diagram

```text
main.tf                       terraform.tfstate
------                        -----------------
aws_instance.web  --------->  i-0123456789abcdef0
aws_s3_bucket.app --------->  my-app-bucket-12345

Terraform compares:

configuration + state + remote refresh -> plan
```

### Step-by-step example

After applying:

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-state-demo-bucket-12345"
}
```

Terraform state records that `aws_s3_bucket.example` exists and has AWS attributes. On the next run, Terraform refreshes that object and checks for drift.

Useful commands:

```bash
terraform state list
terraform state show aws_s3_bucket.example
terraform plan -refresh-only
```

### Production best practices

- Do not commit `terraform.tfstate` or `*.tfstate.backup`.
- Use remote state, commonly S3 with DynamoDB locking for AWS teams.
- Enable encryption on the state bucket.
- Restrict state access because state can contain secrets.
- Back up state and protect it with versioning.
- Use state locking to prevent concurrent applies.
- Treat state operations (`state rm`, `state mv`, imports) as production changes.

### Common mistakes and troubleshooting

- **Mistake:** Deleting state to "start fresh."
  - **Result:** Terraform forgets ownership and may attempt duplicate resources.
  - **Fix:** Restore from backup or import existing resources.
- **Mistake:** Concurrent applies.
  - **Result:** State corruption or conflicting changes.
  - **Fix:** Use a locking backend.
- **Mistake:** Editing state by hand.
  - **Fix:** Use `terraform state` commands and backups.
- **Mistake:** Assuming `sensitive = true` removes values from state.
  - **Fix:** It hides CLI output, but sensitive values may still be stored in state.

---

## 8. Lifecycle of Terraform Execution

### Concept

Terraform has a predictable lifecycle:

1. Write configuration.
2. Initialize the working directory.
3. Format and validate.
4. Plan changes.
5. Apply approved changes.
6. Store updated state.
7. Repeat as infrastructure evolves.

### Why it exists

Production infrastructure changes need repeatable workflow and review. Terraform separates planning from applying so humans and automation can inspect consequences.

### ASCII diagram

```text
write .tf
   |
   v
terraform init
   |
   v
terraform fmt -> terraform validate
   |
   v
terraform plan
   |
   v
review
   |
   v
terraform apply
   |
   v
state updated
```

### Step-by-step example

```bash
# 1. Download providers and configure backend
terraform init

# 2. Standardize formatting
terraform fmt -recursive

# 3. Static configuration validation
terraform validate

# 4. Preview changes
terraform plan -out=tfplan

# 5. Apply exactly the reviewed plan
terraform apply tfplan

# 6. Inspect outputs
terraform output
```

### Terraform/HCL code used in this module project

```hcl
resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-web"
  }
}
```

### Production best practices

- Save plans in CI when the apply should match an approved plan.
- Run plans on pull requests.
- Run applies only from protected branches or approved workflows.
- Use `-target` only for exceptional recovery work.
- Read replacement actions carefully; replacements can cause downtime.
- Prefer immutable changes and blue/green strategies for critical systems.

### Common mistakes and troubleshooting

- **Mistake:** Applying a stale plan after code or remote resources changed.
  - **Fix:** Regenerate plans close to apply time.
- **Mistake:** Ignoring `-/+` replacement markers.
  - **Fix:** Treat replacements as high-risk until understood.
- **Mistake:** Using `-auto-approve` from a laptop in production.
  - **Fix:** Reserve automation for controlled CI/CD workflows.

---

## Hands-on exercises

1. **Read a plan like a change ticket**
   - Create an S3 bucket resource.
   - Run `terraform plan`.
   - Identify which attributes are known before apply and which are known after apply.

2. **Create and modify infrastructure**
   - Apply an EC2 instance.
   - Change the instance type from `t3.micro` to `t2.micro` or the reverse.
   - Run `terraform plan` and determine whether Terraform updates or replaces the instance.

3. **Observe drift**
   - Create a tag with Terraform.
   - Change that tag manually in the AWS Console.
   - Run `terraform plan` and observe how Terraform proposes to restore the configured value.

See `exercises/README.md` for hints.

---

## Mini project: Provision EC2 + S3

The project in `project/` creates:

- One S3 bucket with versioning and encryption.
- One security group allowing SSH from your IP and HTTP from anywhere.
- One EC2 instance using a simple `user_data` script to run a web server.

Expected workflow:

```bash
cd modules/01-iac-fundamentals/project
cp terraform.tfvars.example terraform.tfvars
# edit bucket_name and ssh_cidr_block
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, open the `web_url` output in a browser. Destroy the environment when finished:

```bash
terraform destroy
```

---

## Advanced topics to explore after this module

- Remote state with S3 and DynamoDB locking.
- Importing existing AWS resources into Terraform.
- Drift detection in CI.
- Policy as code with tools such as Open Policy Agent or Sentinel.
- Module versioning and private module registries.
- Multi-account AWS provider aliases.
- Separating bootstrap infrastructure from application infrastructure.

---

## Interview prep Q&A

### 1. What problem does Infrastructure as Code solve?

It makes infrastructure reproducible, reviewable, auditable, and automatable. Instead of relying on manual console actions, infrastructure is defined in version-controlled configuration and applied through a repeatable workflow.

### 2. What is the difference between imperative and declarative infrastructure management?

Imperative management specifies step-by-step commands. Declarative management specifies the desired final state. Terraform is declarative: it computes the actions needed to make real infrastructure match configuration.

### 3. Why does Terraform need a state file?

State maps Terraform resource addresses to real remote objects and stores computed attributes. Without state, Terraform would not know which EC2 instance or S3 bucket is managed by which resource block.

### 4. Why should Terraform state not be committed to Git?

State can contain sensitive data and environment-specific resource metadata. Teams should use a secure remote backend with encryption, access controls, versioning, and locking.

### 5. What is a Terraform provider?

A provider is a plugin that implements resources and data sources for an API. The AWS provider translates Terraform configuration into AWS API calls.

### 6. How does Terraform determine resource creation order?

Terraform builds a dependency graph from references between resources and data sources. It creates independent resources in parallel and respects graph dependencies.

### 7. When should you use `depends_on`?

Use `depends_on` only when a real dependency is not visible through attribute references. Most dependencies should be expressed naturally by referencing resource attributes.

### 8. What is the difference between `terraform plan` and `terraform apply`?

`plan` previews proposed changes. `apply` executes changes and updates state. In production, plans should be reviewed before apply.

### 9. What does provider version pinning protect against?

It prevents accidental behavior changes from new provider releases. Provider upgrades should be intentional and reviewed.

### 10. What is infrastructure drift?

Drift occurs when real infrastructure changes outside Terraform or differs from configuration. Terraform detects drift during refresh and plans changes to restore the declared state.

---

## Real-world case study: From console-built staging to Terraform-managed production

A backend team owns an API running on EC2 with S3 for file uploads. The first staging environment was created manually during a deadline. Over time, staging and production diverged:

- Staging allowed SSH from anywhere; production allowed only the office VPN.
- The production S3 bucket had versioning, but staging did not.
- Tags were inconsistent, so cost reports were unreliable.
- Nobody knew whether a security group rule was still needed.

The team introduced Terraform in three steps.

### Step 1: Document desired infrastructure

They wrote Terraform for the target shape rather than copying every accidental staging detail:

- EC2 instance.
- Security group with explicit SSH and HTTP rules.
- S3 bucket with versioning and server-side encryption.
- Required tags.

### Step 2: Create a fresh development environment

They applied Terraform to a new dev environment first. This reduced risk because they could test the workflow without touching production.

### Step 3: Move production carefully

For production, they imported existing resources into state, reviewed plans until Terraform showed no unexpected changes, then made future changes only through Terraform pull requests.

### Result

- New environments could be created in under 30 minutes.
- Security reviews happened in pull requests.
- S3 encryption and versioning became standard.
- Drift was detected during regular plans.
- On-call engineers had a clear source of truth during incidents.

The key lesson: Terraform is not just a provisioning tool. In production engineering, it is a collaboration and safety mechanism for infrastructure change.
