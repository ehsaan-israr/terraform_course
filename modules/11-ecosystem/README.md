# Module 11: Terraform Ecosystem

Terraform is the engine that turns configuration into infrastructure changes. Production teams usually need a larger delivery system around that engine: pull request automation, policy checks, cost review, remote state, reusable modules, private networking, secure credentials, drift detection, and a clear audit trail.

This module teaches the ecosystem tools you will see in real AWS platform teams: Terragrunt, Atlantis, Terraform Cloud, Spacelift, OpenTofu, and Infracost. The goal is not to collect tools. The goal is to choose the smallest workflow that gives your team safe, reviewable, repeatable infrastructure changes.

> Region used in examples: `us-east-1`.

---

## Learning objectives

By the end of this module you should be able to:

- Explain what each ecosystem tool is and why it exists.
- Design a pull-request-based GitOps workflow for Terraform or OpenTofu.
- Compare self-hosted automation with managed platforms.
- Decide when Terragrunt is helpful and when plain Terraform roots are better.
- Add cost estimation, policy checks, and run tasks to infrastructure delivery.
- Explain OpenTofu migration considerations in a senior engineering interview.
- Design AWS credentials for CI/CD without long-lived access keys.
- Troubleshoot common failures in automated plan and apply systems.

---

## 1. The ecosystem mental model

Terraform solves this core loop:

```text
HCL configuration + state + provider plugins -> plan -> apply -> cloud APIs
```

The ecosystem solves the team loop around it:

```text
Engineer -> branch -> pull request -> checks -> plan -> review -> apply -> drift monitoring
```

In small teams, the loop can be a Makefile, S3 state, DynamoDB locking, and GitHub Actions. In larger teams, the loop often becomes a platform with separate runners, policy engines, cost checks, private module registries, stack dependencies, audit controls, and production approvals.

### What belongs around Terraform?

- **State and locking**: S3 plus DynamoDB, Terraform Cloud state, Spacelift state, or another remote backend.
- **Execution environment**: local machine, CI runner, Atlantis pod, Terraform Cloud agent, Spacelift worker, or self-hosted runner.
- **Credentials**: OIDC-assumed AWS roles, short-lived tokens, or platform-managed dynamic credentials.
- **Review controls**: pull requests, CODEOWNERS, approvals, protected branches, policy checks.
- **Feedback**: plan comments, cost estimates, security scans, drift alerts, audit logs.
- **Reusable catalog**: private modules, provider mirrors, standard root module templates.

### Design principle

Add a tool when it removes an operational risk you actually have:

- Repeated remote-state boilerplate across 100 roots? Consider Terragrunt.
- Local production applies from laptops? Add PR automation or remote execution.
- Compliance needs centralized audit and policy? Consider Terraform Cloud or Spacelift.
- Engineers surprise Finance with expensive resources? Add Infracost.
- License policy requires open-source IaC tooling? Evaluate OpenTofu.

---

## 2. Terragrunt

### Concept / what it is

Terragrunt is a thin wrapper around Terraform or OpenTofu. It runs the underlying binary but adds features for managing many root modules:

- DRY remote backend configuration.
- Hierarchical configuration using `include` blocks.
- Shared inputs and locals across account, region, and environment folders.
- Dependency output wiring between stacks.
- `run-all` commands across multiple stacks.
- Before and after hooks for common commands.

Terraform modules reduce duplication inside infrastructure definitions. Terragrunt reduces duplication around live stack configuration.

### Why it exists

Plain Terraform intentionally keeps a root module self-contained. That is good for clarity, but large AWS estates often have hundreds of near-identical root modules:

```text
accounts/
  dev/us-east-1/network
  dev/us-east-1/app
  staging/us-east-1/network
  staging/us-east-1/app
  prod/us-east-1/network
  prod/us-east-1/app
```

Without a wrapper, each root may repeat:

- S3 backend bucket and key conventions.
- AWS provider assume-role settings.
- Common tags.
- Account IDs.
- Region variables.
- References to dependency outputs.

Terragrunt gives platform teams a way to standardize that live wiring without turning every root module into a giant configurable module.

### Real-world use cases

- Multi-account AWS repositories with one folder per account, region, and stack.
- Reusing the same VPC module across dev, staging, and production with different CIDRs.
- Passing VPC outputs into ECS, RDS, or Redis stacks.
- Running `plan` across all stacks affected by a shared module change.
- Enforcing consistent S3 state naming and DynamoDB locks.
- Generating provider files so engineers do not copy-paste assume-role blocks.

### How it works internally

Terragrunt reads `terragrunt.hcl`, resolves includes and dependencies, generates temporary Terraform configuration, then invokes Terraform or OpenTofu.

```text
terragrunt.hcl
   |
   | parse include, locals, inputs, dependencies
   v
Terragrunt engine
   |
   +--> downloads module source into .terragrunt-cache/
   |
   +--> generates backend/provider files if configured
   |
   +--> reads dependency outputs using terraform output
   |
   v
terraform/tofu init/plan/apply
   |
   v
remote backend + cloud APIs
```

For `run-all`, Terragrunt builds a dependency graph:

```text
network
   |
   +--> security-groups
   |
   +--> database
            |
            v
          service
```

It plans or applies in dependency order and can parallelize independent stacks.

### Setup and example config snippets

Common repository layout:

```text
live/
  terragrunt.hcl
  prod/
    account.hcl
    us-east-1/
      region.hcl
      network/terragrunt.hcl
      app/terragrunt.hcl
modules/
  vpc/
  ecs-service/
```

Root `live/terragrunt.hcl`:

```hcl
locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  account_id  = local.account_vars.locals.account_id
  environment = local.account_vars.locals.environment
  region      = local.region_vars.locals.region
}

remote_state {
  backend = "s3"

  config = {
    bucket         = "example-tfstate-${local.account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region = "${local.region}"

  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/terraform-execution"
  }

  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}
```

`prod/account.hcl`:

```hcl
locals {
  account_id  = "111122223333"
  environment = "prod"
}
```

`prod/us-east-1/region.hcl`:

```hcl
locals {
  region = "us-east-1"
}
```

`prod/us-east-1/network/terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  name               = "prod-use1"
  cidr_block         = "10.20.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

`prod/us-east-1/app/terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/ecs-service"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  service_name       = "api"
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
}
```

Useful commands:

```bash
terragrunt init
terragrunt plan
terragrunt apply
terragrunt run-all plan
terragrunt graph-dependencies
```

### Production best practices

- Keep Terragrunt live configuration thin. Business logic belongs in Terraform modules.
- Use one root per deployable stack: network, database, cache, service, edge.
- Pin module sources to tags or immutable commits for production.
- Use `dependency` outputs for stable values, not large objects.
- Keep state keys deterministic and based on folder paths.
- Avoid `run-all apply` to production unless your dependency graph and approvals are mature.
- Review generated files locally when introducing `generate` blocks.
- Document the folder hierarchy. New engineers should know where account, region, and stack values come from.

### Common mistakes and troubleshooting

- **Mistake:** Putting complex conditional infrastructure logic in `terragrunt.hcl`.
  - **Symptom:** Plans are hard to reason about and modules become difficult to test.
  - **Fix:** Move resource logic into modules; keep Terragrunt as live wiring.
- **Mistake:** Using floating module sources such as a branch name in production.
  - **Symptom:** A plan changes even though the live folder did not.
  - **Fix:** Pin to tags or commit SHAs.
- **Mistake:** Circular dependencies between stacks.
  - **Symptom:** `run-all` cannot build a graph.
  - **Fix:** Split shared primitives or move the dependency boundary.
- **Mistake:** Overusing `run-all apply`.
  - **Symptom:** Too many changes land in one operation.
  - **Fix:** Apply high-risk stacks separately and keep PRs small.
- **Troubleshooting:** Delete `.terragrunt-cache/` when module source changes behave unexpectedly.

### When NOT to use Terragrunt

- You have fewer than a handful of root modules.
- Your team is still learning Terraform basics and needs less abstraction.
- Your CI platform already provides all needed stack composition.
- The live configuration becomes harder to understand than copied backend blocks.
- You need strict support from a vendor that does not support Terragrunt workflows.

---

## 3. Atlantis

### Concept / what it is

Atlantis is a self-hosted pull request automation service for Terraform and OpenTofu. It listens to GitHub, GitLab, Bitbucket, or Azure DevOps webhooks, runs plans for changed projects, comments results on pull requests, locks projects, and applies after approval.

The common user experience:

```text
Engineer opens PR
Atlantis comments terraform plan
Reviewer approves
Engineer comments "atlantis apply"
Atlantis applies from a controlled runner
```

### Why it exists

Teams outgrow local Terraform when:

- Two engineers can apply the same stack at the same time.
- Production credentials live on laptops.
- Plan output is not attached to code review.
- State locking exists but human workflow still races.
- Auditors cannot tell who approved a change.

Atlantis makes Terraform changes visible in pull requests while letting you own the runtime, network, and credentials.

### Real-world use cases

- Private AWS accounts where runners need VPC access to internal endpoints.
- Regulated teams that do not want remote execution in a SaaS service.
- Organizations already running Kubernetes and comfortable operating webhooks.
- Monorepos with many Terraform roots and project-specific workflows.
- Teams that want a simple GitOps workflow without adopting a full IaC platform.

### How it works internally

```text
Git provider
  |
  | pull_request webhook
  v
Atlantis server
  |
  +--> clones repository
  +--> detects changed projects
  +--> acquires Atlantis project lock
  +--> runs terraform init/plan
  +--> stores plan file on Atlantis disk/object storage
  +--> comments result on PR
  |
  | "atlantis apply" comment after approval
  v
Terraform apply
  |
  v
remote backend lock + AWS APIs
```

There are two lock layers:

- Atlantis project lock prevents competing PRs from applying the same project.
- Terraform backend lock prevents concurrent state writes.

### Setup and example config snippets

Minimal `atlantis.yaml` in the repository:

```yaml
version: 3
automerge: false
parallel_plan: true
parallel_apply: false

projects:
  - name: prod-network
    dir: live/prod/us-east-1/network
    workspace: default
    terraform_version: v1.6.6
    autoplan:
      enabled: true
      when_modified:
        - "*.tf"
        - "*.tfvars"
        - "../../../modules/vpc/**/*.tf"
    apply_requirements:
      - approved
      - mergeable
```

Custom workflow with Infracost and validation:

```yaml
version: 3

workflows:
  secure-plan:
    plan:
      steps:
        - run: terraform fmt -check -recursive
        - init
        - run: terraform validate
        - plan
        - run: infracost breakdown --path "$PLANFILE" --format json --out-file infracost.json
    apply:
      steps:
        - apply

projects:
  - name: staging-app
    dir: live/staging/us-east-1/app
    workflow: secure-plan
```

Kubernetes deployment sketch:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: atlantis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: atlantis
  template:
    metadata:
      labels:
        app: atlantis
    spec:
      serviceAccountName: atlantis
      containers:
        - name: atlantis
          image: ghcr.io/runatlantis/atlantis:latest
          args:
            - server
            - --repo-allowlist=github.com/example/*
            - --atlantis-url=https://atlantis.example.com
          envFrom:
            - secretRef:
                name: atlantis-webhook-and-vcs-token
```

### Production best practices

- Run Atlantis with persistent storage for plan files.
- Use repository allowlists and webhook secrets.
- Require PR approval before production apply.
- Use OIDC, IRSA, or short-lived role assumption instead of static AWS keys.
- Keep Atlantis patched and restrict who can issue apply commands.
- Make `atlantis.yaml` changes require platform-team approval.
- Separate staging and production projects with different AWS roles.
- Send Atlantis logs to centralized logging.
- Add policy and security checks before the plan is approved.

### Common mistakes and troubleshooting

- **Mistake:** Atlantis can plan but cannot apply.
  - **Likely cause:** Plan file was lost because storage is ephemeral.
  - **Fix:** Use persistent volume or object storage depending on deployment mode.
- **Mistake:** Every PR triggers every project.
  - **Likely cause:** `when_modified` patterns are too broad.
  - **Fix:** Tune project definitions and module path patterns.
- **Mistake:** Engineers bypass Atlantis by applying locally.
  - **Fix:** Remove local production permissions and require CI assume-role conditions.
- **Mistake:** Lock remains after an abandoned PR.
  - **Fix:** Use `atlantis unlock` with platform approval and verify no apply is running.
- **Mistake:** Atlantis has admin permissions everywhere.
  - **Fix:** Use account-specific roles and least privilege where practical.

### When NOT to use Atlantis

- You do not want to operate a webhook service.
- You need rich native policy, drift, dependency, and dashboard features out of the box.
- Your organization prefers a managed SaaS control plane.
- You cannot expose a webhook endpoint or reliable inbound tunnel.
- You need multi-IaC orchestration beyond Terraform/OpenTofu without custom workflows.

---

## 4. Terraform Cloud

### Concept / what it is

Terraform Cloud is HashiCorp's managed platform for Terraform workflows. It provides remote state, remote execution, VCS-driven runs, private module registry, team access controls, variable sets, policy as code, run tasks, drift detection, agents, and audit capabilities.

Terraform Enterprise is the self-hosted version for organizations that need to run the platform inside their own environment.

### Why it exists

Terraform's CLI is powerful, but enterprises need:

- Centralized state and locking.
- Consistent execution environments.
- RBAC for who can plan, apply, and manage variables.
- Private module distribution.
- Audit logs.
- Policy checks before apply.
- A supported managed workflow.

Terraform Cloud packages these capabilities so teams do not have to assemble every part themselves.

### Real-world use cases

- VCS-driven Terraform applies for many teams.
- Secure remote state with workspace-level permissions.
- Publishing approved AWS modules in a private registry.
- Enforcing Sentinel or OPA policies before production applies.
- Running agents inside a private AWS VPC while control remains SaaS.
- Standardizing environment variables and provider credentials through variable sets.

### How it works internally

```text
Git provider
  |
  | VCS webhook
  v
Terraform Cloud workspace
  |
  +--> queues run
  +--> resolves variables and variable sets
  +--> executes plan on managed runner or private agent
  +--> runs policies and run tasks
  +--> waits for approval if required
  +--> executes apply
  |
  v
Terraform Cloud state storage + AWS APIs
```

Private agent architecture:

```text
Terraform Cloud SaaS
       |
       | outbound agent connection
       v
Agent pool in private VPC
       |
       +--> internal APIs
       +--> AWS private endpoints
       +--> Terraform providers
```

The agent initiates outbound communication, which avoids opening inbound access to private networks.

### Setup and example config snippets

CLI-driven workspace backend:

```hcl
terraform {
  cloud {
    organization = "example-platform"

    workspaces {
      name = "prod-network"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

VCS-driven workspaces are commonly configured in the Terraform Cloud UI or with the `tfe` provider:

```hcl
resource "tfe_workspace" "prod_network" {
  name         = "prod-network"
  organization = var.tfc_organization
  auto_apply   = false
  queue_all_runs = false

  vcs_repo {
    identifier     = "example/infra-live"
    branch         = "main"
    oauth_token_id = var.oauth_token_id
  }
}

resource "tfe_variable" "aws_region" {
  workspace_id = tfe_workspace.prod_network.id
  key          = "AWS_REGION"
  value        = "us-east-1"
  category     = "env"
}
```

AWS OIDC dynamic credentials pattern:

```hcl
variable "tfc_aws_dynamic_credentials" {
  type = object({
    default = object({
      shared_config_file = string
    })
    aliases = map(object({
      shared_config_file = string
    }))
  })
}

provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = [var.tfc_aws_dynamic_credentials.default.shared_config_file]
}
```

### Production best practices

- Disable auto-apply for production workspaces.
- Use workspace naming that includes account, region, and stack.
- Put shared environment variables in variable sets.
- Use dynamic credentials or agents instead of static cloud keys.
- Require policy checks for security-critical resources.
- Use run tasks for security scanning, cost checks, and CMDB notifications.
- Separate state by blast radius; avoid one giant workspace.
- Use the private registry for blessed modules and version modules semantically.
- Document workspace ownership and escalation paths.

### Common mistakes and troubleshooting

- **Mistake:** Treating workspaces as application environments without clear state boundaries.
  - **Fix:** Model workspaces as deployable stacks with explicit dependencies.
- **Mistake:** Storing secrets as plain Terraform variables.
  - **Fix:** Mark sensitive variables and prefer external secret stores when possible.
- **Mistake:** Assuming remote execution can reach private endpoints.
  - **Fix:** Use agents in the network path or expose required APIs safely.
- **Mistake:** Policy failures are ignored until release day.
  - **Fix:** Run policies in advisory mode first, then make them mandatory after cleanup.
- **Mistake:** Drift detection produces noise.
  - **Fix:** Decide which resources Terraform owns and stop manual mutation.

### When NOT to use Terraform Cloud

- Your organization cannot use the HashiCorp platform for legal, network, or cost reasons.
- You require a fully open-source workflow and avoid vendor control planes.
- You need orchestration across many IaC tools in one platform.
- Your simple CI plus S3 backend workflow already satisfies the risk profile.
- You want to run OpenTofu as a first-class engine without compatibility questions.

---

## 5. Spacelift

### Concept / what it is

Spacelift is a managed infrastructure orchestration platform. It supports Terraform, OpenTofu, Terragrunt, Pulumi, CloudFormation, Ansible, Kubernetes, and custom workflows. Its core unit is a stack: a repository path plus runtime configuration, policies, dependencies, contexts, state, and workers.

### Why it exists

Many platform teams do not only run Terraform. They also run Kubernetes manifests, Helm, Pulumi, Ansible, and policy checks. They need:

- A control plane for multiple IaC tools.
- Stack dependencies and run ordering.
- Policy as code at login, plan, approval, and task stages.
- Drift detection.
- Self-hosted workers for private networks.
- Flexible contexts for shared variables and credentials.

Spacelift competes with "build it yourself in CI" by providing a specialized IaC delivery platform.

### Real-world use cases

- Multi-cloud organizations using Terraform and Kubernetes.
- Enterprises standardizing OpenTofu while keeping policy and audit controls.
- Teams that want private workers but do not want to operate Atlantis.
- Platform groups that need stack dependencies across networking, data, and apps.
- Organizations with complex policy requirements before and after plan.

### How it works internally

```text
Git provider
  |
  | webhook
  v
Spacelift control plane
  |
  +--> matches changed stack
  +--> attaches contexts
  +--> schedules worker
  +--> runs init/plan
  +--> evaluates policies
  +--> waits for approval if required
  +--> runs apply
  |
  v
state backend + AWS APIs
```

Private worker pool:

```text
Spacelift SaaS
      |
      | outbound worker connection
      v
Worker pool in AWS account
      |
      +--> assume target roles
      +--> reach private module registry
      +--> reach private AWS endpoints
```

Stack dependency model:

```text
network stack -> data stack -> app stack -> edge stack
```

### Setup and example config snippets

Stack configuration can be managed through the UI, API, Terraform provider, or `.spacelift/config.yml`.

Example `.spacelift/config.yml`:

```yaml
version: "1"

stack_defaults:
  before_init:
    - terraform fmt -check -recursive
  before_plan:
    - terraform validate

stacks:
  prod-network:
    project_root: live/prod/us-east-1/network
    branch: main
    terraform_version: "1.6.6"
    autodeploy: false

  prod-app:
    project_root: live/prod/us-east-1/app
    branch: main
    terraform_version: "1.6.6"
    autodeploy: false
    dependencies:
      - prod-network
```

Stack with the Spacelift Terraform provider:

```hcl
resource "spacelift_stack" "prod_app" {
  name        = "prod-app"
  repository  = "infra-live"
  branch      = "main"
  project_root = "live/prod/us-east-1/app"

  terraform_version = "1.6.6"
  autodeploy        = false
  administrative    = false
}

resource "spacelift_context_attachment" "prod" {
  context_id = spacelift_context.prod.id
  stack_id   = spacelift_stack.prod_app.id
  priority   = 0
}
```

OPA policy sketch:

```rego
package spacelift

deny[msg] {
  input.run.type == "PROPOSED"
  some rc
  rc := input.terraform.resource_changes[_]
  rc.type == "aws_s3_bucket_public_access_block"
  not rc.change.after.block_public_acls
  msg := "S3 public ACL blocking must remain enabled"
}
```

### Production best practices

- Model stacks around state boundaries, not team politics.
- Use contexts for shared non-secret variables and short-lived credential setup.
- Use private workers for private AWS access and controlled egress.
- Write policies gradually: advisory, then mandatory after false positives are fixed.
- Keep stack dependencies explicit and avoid long dependency chains.
- Use drift detection on high-value stacks, but tune frequency to reduce noise.
- Standardize labels and stack naming by account, region, and service.
- Keep administrative stacks tightly controlled because they can manage Spacelift itself.

### Common mistakes and troubleshooting

- **Mistake:** Building one stack per tiny resource.
  - **Symptom:** Dependency overhead and noisy runs.
  - **Fix:** Group by lifecycle and blast radius.
- **Mistake:** Building one huge stack for an entire account.
  - **Symptom:** Slow plans and risky applies.
  - **Fix:** Split network, data, app, edge, and observability stacks.
- **Mistake:** Policies depend on unstable plan details.
  - **Fix:** Test policies with real plans and keep messages actionable.
- **Mistake:** Worker cannot fetch private modules.
  - **Fix:** Check network egress, credentials, and registry trust.
- **Mistake:** Drift detection creates alerts for intentionally external changes.
  - **Fix:** Clarify ownership or use `ignore_changes` only where justified.

### When NOT to use Spacelift

- You only need a simple PR plan comment and can operate Atlantis cheaply.
- Your organization has standardized on Terraform Cloud and does not need multi-tool orchestration.
- You are not ready to model stacks, contexts, workers, and policies.
- The cost and platform adoption burden outweigh the workflow risk.
- A heavily customized internal CI platform already provides equivalent controls.

---

## 6. OpenTofu

### Concept / what it is

OpenTofu is an open-source infrastructure as code engine forked from Terraform after Terraform's license changed from MPL to BUSL. It aims to remain compatible with Terraform configuration, providers, modules, and state while continuing development under an open-source license.

The CLI is similar:

```bash
tofu init
tofu plan
tofu apply
tofu state list
```

### Why it exists

Organizations care about infrastructure tooling license risk because it sits in the critical path of deployment. OpenTofu exists for teams that want:

- An open-source license posture.
- Community governance.
- Terraform-compatible workflows.
- Reduced dependency on one vendor's licensing decisions.

### Real-world use cases

- Enterprises with open-source-only procurement rules.
- Platform teams that want Terraform-compatible HCL but not Terraform's license.
- Managed IaC platforms that need an open-source engine.
- Organizations creating a long-term IaC standard and wanting governance optionality.

### How it works internally

OpenTofu uses the same general architecture:

```text
HCL configuration
   |
   v
OpenTofu CLI
   |
   +--> reads state
   +--> downloads providers
   +--> builds dependency graph
   +--> creates plan
   +--> calls provider RPCs
   v
cloud APIs
```

Compatibility layers:

```text
Terraform-style modules  -> OpenTofu module installer
Terraform providers      -> OpenTofu provider installer
Terraform state          -> OpenTofu state reader/writer
Terraform CLI workflow   -> tofu CLI commands
```

### Setup and example config snippets

The configuration can often remain unchanged:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "example-tfstate"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Migration checklist:

```bash
terraform version
terraform init -upgrade=false
terraform plan -out=tfplan

tofu version
tofu init -upgrade=false
tofu plan
```

CI command switch:

```yaml
steps:
  - run: tofu fmt -check -recursive
  - run: tofu init -input=false
  - run: tofu validate
  - run: tofu plan -input=false -out=tfplan
```

### Production best practices

- Test OpenTofu against non-production workspaces first.
- Pin provider versions before migration.
- Do not upgrade providers and switch engines in the same PR.
- Confirm your automation platform supports OpenTofu.
- Confirm module registry sources and mirrors work as expected.
- Keep a state backup before the first production `tofu apply`.
- Document whether new projects should use Terraform or OpenTofu to avoid split-brain tooling.

### Common mistakes and troubleshooting

- **Mistake:** Assuming every vendor feature in Terraform Cloud works with OpenTofu.
  - **Fix:** Validate platform support explicitly.
- **Mistake:** Engine migration plus module refactor plus provider upgrade in one change.
  - **Fix:** Separate the changes.
- **Mistake:** Local aliases mix `terraform` and `tofu`.
  - **Fix:** Make CI authoritative and document commands.
- **Mistake:** Ignoring provider installation differences.
  - **Fix:** Test provider mirrors and lock files.
- **Troubleshooting:** If a plan differs unexpectedly, compare CLI versions, provider lock files, environment variables, and backend configuration.

### When NOT to use OpenTofu

- Your organization requires HashiCorp-supported Terraform features.
- You rely deeply on Terraform Cloud workflows that do not support OpenTofu.
- You cannot afford a migration test cycle.
- Your team has no license, cost, governance, or vendor-neutrality concern.
- Tool standardization is more valuable than switching engines right now.

---

## 7. Infracost

### Concept / what it is

Infracost estimates cloud cost changes from Terraform or OpenTofu plans. It can run locally or in CI and commonly comments on pull requests with monthly cost deltas.

It does not replace billing, budgets, or FinOps analysis. It gives engineers cost feedback before infrastructure is applied.

### Why it exists

Cost surprises often start in code review:

- A database instance size changes.
- NAT gateways are added in every AZ.
- A load balancer is created for every preview environment.
- Retention or backup settings increase storage.
- A cache cluster is scaled up.

Without cost feedback, reviewers must mentally price the plan. Infracost makes the financial impact visible next to the technical diff.

### Real-world use cases

- PR comments showing monthly cost delta for AWS resources.
- Blocking production PRs when cost exceeds a threshold without approval.
- Highlighting expensive resources to FinOps reviewers.
- Comparing alternative designs during architecture review.
- Teaching engineers the cost impact of NAT gateways, RDS, and data transfer.

### How it works internally

```text
Terraform/OpenTofu plan
      |
      | show plan as JSON
      v
Infracost CLI
      |
      +--> parses resource changes
      +--> maps resources to cloud pricing data
      +--> applies usage assumptions
      +--> calculates monthly estimate
      v
PR comment / JSON report / CI status
```

PR workflow:

```text
plan.out -> terraform show -json plan.out -> infracost breakdown -> infracost comment
```

### Setup and example config snippets

Local estimate:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
infracost breakdown --path plan.json
```

Usage file for assumptions Terraform cannot know:

```yaml
version: 0.1
resource_usage:
  aws_nat_gateway.main:
    monthly_data_processed_gb: 500
  aws_cloudfront_distribution.cdn:
    monthly_data_transfer_to_internet_gb:
      us: 1000
    monthly_requests:
      us: 50000000
```

GitHub Actions sketch:

```yaml
name: terraform-cost

on:
  pull_request:

jobs:
  infracost:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: infracost/actions/setup@v3
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}
      - run: terraform init -input=false
      - run: terraform plan -out=tfplan -input=false
      - run: terraform show -json tfplan > plan.json
      - run: infracost breakdown --path plan.json --format json --out-file infracost.json
      - run: infracost comment github --path infracost.json --repo "$GITHUB_REPOSITORY" --pull-request "$PR_NUMBER" --behavior update
        env:
          GITHUB_TOKEN: ${{ github.token }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
```

### Production best practices

- Treat estimates as decision support, not exact bills.
- Maintain usage files for data transfer, requests, and storage growth.
- Add FinOps review when monthly delta exceeds a threshold.
- Show both absolute monthly estimate and delta from baseline.
- Keep cost checks advisory at first so teams learn the numbers.
- Combine Infracost with AWS Budgets, Cost Explorer, and tagging.
- Put cost ownership tags in Terraform modules.

### Common mistakes and troubleshooting

- **Mistake:** Expecting exact billing.
  - **Fix:** Explain that actual bills include usage, discounts, taxes, support, and shared costs.
- **Mistake:** Ignoring usage assumptions.
  - **Fix:** Add usage files for traffic-sensitive services.
- **Mistake:** Running Infracost against HCL only when plan JSON is available.
  - **Fix:** Prefer plan JSON for proposed changes.
- **Mistake:** Blocking every cost increase.
  - **Fix:** Route meaningful increases to review; do not punish normal growth.
- **Troubleshooting:** If a resource is missing, check Infracost resource support and whether the plan JSON contains enough attributes.

### When NOT to use Infracost

- Your Terraform changes do not materially affect cloud spend.
- You already have a strong FinOps workflow and PR estimates would be noise.
- The team will treat estimates as exact accounting numbers.
- You cannot provide usage assumptions for the resources under review.

---

## 8. Full comparison matrix

| Tool | Primary role | Execution model | State support | Policy support | Cost visibility | Drift detection | Ops burden | Cost model | Lock-in risk | Best fit |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Terragrunt | Live configuration wrapper | Runs local/CI Terraform or OpenTofu | Uses Terraform/OpenTofu backends | External tools | External tools | External tools | Low to medium; you own conventions | Open-source tool cost plus runner cost | Medium workflow lock-in from `terragrunt.hcl` layout | Many similar stacks across accounts and regions |
| Atlantis | PR automation | Self-hosted server runs CLI | Uses configured backend | Custom workflows; external policy tools | External Infracost integration | External/scheduled jobs | Medium; operate server, webhooks, storage, upgrades | Infrastructure and maintenance cost | Low to medium; repo config portable but commands are Atlantis-specific | Teams wanting self-hosted PR plans and applies |
| Terraform Cloud | Managed Terraform platform | Managed runners or private agents | Native remote state | Sentinel, run tasks, integrations | Run tasks/Infracost integration | Native drift features | Low for SaaS; medium with agents | SaaS pricing by current model plus agents | Medium to high from workspace, registry, policy, and state integration | Teams wanting managed Terraform workflow |
| Spacelift | IaC orchestration platform | Managed control plane plus public/private workers | Native or external depending workflow | OPA policies across stages | Integrations and custom hooks | Native drift features | Low to medium; platform modeling required | SaaS pricing by stack/worker model | Medium from stack/context/policy model | Multi-tool IaC platform teams |
| OpenTofu | IaC engine | CLI in local/CI/platform runners | Terraform-compatible backends | External/platform policy | External Infracost integration | External/platform drift | Low if replacing Terraform CLI; migration testing required | Open-source tool cost plus runner/platform | Low engine lock-in; ecosystem support still matters | License-sensitive Terraform-compatible teams |
| Infracost | Cost estimation | CLI in local/CI/PR workflow | Reads plan JSON; no state ownership | Can enforce thresholds externally | Native purpose | No | Low; maintain usage assumptions | SaaS/API plan plus CI time depending usage | Low; advisory output portable | Teams needing cost feedback in code review |

Feature checklist:

| Capability | Terragrunt | Atlantis | Terraform Cloud | Spacelift | OpenTofu | Infracost |
| --- | --- | --- | --- | --- | --- | --- |
| DRY backend config | Yes | No | No | No | No | No |
| PR plan comments | Via CI integration | Yes | VCS checks, run UI | Yes | Via CI/platform | Yes for cost |
| Remote execution | No | Self-hosted | Yes | Yes | No | No |
| Private workers | Via your CI | Your server | Agents | Worker pools | Via your CI | Via your CI |
| Private module registry | No | No | Yes | Integrates/supports workflows | Provider/module compatible | No |
| Native policy engine | No | No | Yes | Yes | No | No |
| OpenTofu support | Yes | Possible | Varies by platform support | Yes | Native | Yes via plan JSON |
| Best paired with | Terraform/OpenTofu, Atlantis, CI | S3 backend, Infracost, policy scanners | Sentinel, run tasks, agents | OPA, private workers, contexts | Terragrunt, CI, Spacelift | Atlantis, Terraform Cloud, Spacelift, CI |

---

## 9. End-to-end GitOps reference architecture

This reference keeps production credentials out of laptops, makes plans visible in PRs, and records approvals.

```text
                         +----------------------+
                         |  Developer laptop    |
                         |  edit HCL only       |
                         +----------+-----------+
                                    |
                                    | git push
                                    v
                         +----------------------+
                         | Git repository       |
                         | CODEOWNERS           |
                         | protected branches   |
                         +----------+-----------+
                                    |
                         pull request webhook
                                    |
                                    v
        +---------------------------+----------------------------+
        | IaC automation platform                                 |
        | Atlantis, Terraform Cloud, Spacelift, or CI             |
        +---------------------------+----------------------------+
                                    |
        +---------------------------+----------------------------+
        | Checks                                                   |
        | - terraform fmt/validate                                 |
        | - tflint/checkov/tfsec/trivy                             |
        | - terraform/tofu plan                                    |
        | - Infracost estimate                                     |
        | - OPA/Sentinel policy                                    |
        +---------------------------+----------------------------+
                                    |
                         PR comments and statuses
                                    |
                                    v
                         +----------------------+
                         | Human review         |
                         | app owner            |
                         | platform owner       |
                         | security/FinOps      |
                         +----------+-----------+
                                    |
                           approved apply
                                    |
                                    v
        +---------------------------+----------------------------+
        | Apply runner with OIDC-assumed role                     |
        +---------------------------+----------------------------+
                                    |
             +----------------------+---------------------+
             |                                            |
             v                                            v
   +-----------------------+                    +----------------------+
   | Remote state backend  |                    | AWS target accounts  |
   | S3+DynamoDB or SaaS   |                    | dev/stage/prod       |
   +-----------------------+                    +----------------------+
             |                                            |
             v                                            v
   +-----------------------+                    +----------------------+
   | Audit logs            |                    | Drift detection      |
   | CloudTrail/VCS/IaC    |                    | scheduled plan       |
   +-----------------------+                    +----------------------+
```

AWS credential pattern:

```text
CI/OIDC identity
      |
      | sts:AssumeRoleWithWebIdentity
      v
shared-services ci-role
      |
      | sts:AssumeRole
      v
target account terraform-execution role
      |
      v
least-privilege AWS APIs
```

Minimum production gates:

1. Plan must be generated by trusted automation.
2. Plan must be reviewed in the PR.
3. Production apply requires approval from service owner and platform owner.
4. CI role must be the only principal allowed to assume the production Terraform role.
5. State writes must be locked.
6. CloudTrail and IaC platform audit logs must be retained centrally.

---

## 10. Choosing decision tree

```text
Start
 |
 |-- Do you have only a few Terraform roots?
 |       |
 |       +-- Yes --> Use plain Terraform/OpenTofu + remote S3 state + CI.
 |       |
 |       +-- No
 |            |
 |            |-- Is repeated backend/provider/live wiring a real problem?
 |            |       |
 |            |       +-- Yes --> Evaluate Terragrunt.
 |            |       +-- No  --> Keep plain roots.
 |            |
 |-- Do you need PR-based plan/apply automation?
 |       |
 |       +-- No --> Use CI for fmt/validate/security and manual gated apply.
 |       |
 |       +-- Yes
 |            |
 |            |-- Can you use a managed SaaS control plane?
 |            |       |
 |            |       +-- No --> Use Atlantis or internal CI runners.
 |            |       |
 |            |       +-- Yes
 |            |            |
 |            |            |-- Terraform-only and HashiCorp ecosystem desired?
 |            |            |       +-- Yes --> Terraform Cloud.
 |            |            |
 |            |            |-- Multi-IaC, OpenTofu, or flexible workers needed?
 |            |                    +-- Yes --> Spacelift.
 |
 |-- Is license posture a concern?
 |       |
 |       +-- Yes --> Evaluate OpenTofu compatibility and platform support.
 |
 |-- Are cost surprises common?
         |
         +-- Yes --> Add Infracost to PR checks.
```

Senior engineer rule: do not choose based on feature lists alone. Choose based on the failure mode you are trying to remove.

---

## 11. Advanced topics

### Run tasks

Run tasks are external checks invoked during the managed run lifecycle. Terraform Cloud supports run tasks that can call tools such as security scanners, cost systems, or internal approval APIs.

```text
plan complete -> run task webhook -> external system evaluates -> pass/fail/advisory -> apply gate
```

Good run task uses:

- Cost estimation.
- Change-management ticket validation.
- Security scanning.
- CMDB update preview.
- Ownership lookup.

Bad run task uses:

- Long-running mutable operations.
- Hidden applies outside Terraform.
- Business logic that reviewers cannot inspect.

### Policy as code

Policy as code turns infrastructure rules into versioned tests:

- No public S3 buckets.
- RDS must be encrypted.
- Production resources must have owner and cost-center tags.
- IAM policies cannot allow `*` on `*` without exemption.
- Security groups cannot expose SSH to the internet.

Policy engines commonly used with Terraform:

- Sentinel in Terraform Cloud.
- OPA/Rego in Spacelift, Conftest, or CI.
- Checkov, tfsec, Trivy, and Terrascan for static IaC scanning.

Policy best practices:

- Start with high-signal rules.
- Provide actionable failure messages.
- Allow explicit, time-limited exceptions.
- Test policies against real plan JSON.
- Separate advisory checks from mandatory production gates.

### Private registries

Private registries let teams publish approved modules:

```text
platform/vpc/aws
platform/ecs-service/aws
platform/rds-postgres/aws
platform/cloudfront-app/aws
```

Registry benefits:

- Versioned module releases.
- Documentation and examples.
- Standard security defaults.
- Fewer copy-paste implementations.

Module release workflow:

```text
module PR -> tests -> tag v1.4.0 -> registry publish -> live stack version bump PR
```

Avoid publishing every tiny module. A private registry is most valuable when modules represent stable production patterns.

### OIDC and short-lived credentials

OIDC lets CI or an IaC platform exchange an identity token for a cloud role without storing static access keys.

AWS trust policy sketch for GitHub Actions:

```hcl
data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:example/infra-live:ref:refs/heads/main"]
    }
  }
}
```

Production advice:

- Bind roles to repository, branch, environment, and workflow where possible.
- Use separate roles for plan and apply if approval boundaries require it.
- Deny role assumption from local users for production applies.
- Log all role assumptions in CloudTrail.

---

## 12. Hands-on exercises

### Exercise 1: Design the right workflow

Given this scenario:

- 12 AWS accounts.
- 60 Terraform roots.
- Engineers currently plan locally.
- Production state is in S3 with DynamoDB locking.
- Security requires approval before apply.
- Finance wants cost visibility.

Deliver:

1. Choose Atlantis, Terraform Cloud, Spacelift, or CI.
2. Decide whether Terragrunt is justified.
3. Place Infracost and policy checks in the workflow.
4. Draw the GitOps architecture in ASCII.
5. List the minimum AWS roles required.

Acceptance criteria:

- Production credentials are not on laptops.
- Plans are visible in pull requests.
- State locking still exists.
- Cost and policy results are visible before approval.

### Exercise 2: Add cost review to a plan

In any Terraform root from earlier modules:

1. Run a normal plan and save it to `tfplan`.
2. Convert it to JSON.
3. Write an `infracost-usage.yml` file with at least one usage assumption.
4. Run Infracost locally or sketch the CI commands.
5. Explain which numbers are estimates and which are known from configuration.

### Exercise 3: Terragrunt live layout

Create a proposed `live/` layout for dev, staging, and prod:

```text
live/
  terragrunt.hcl
  dev/account.hcl
  staging/account.hcl
  prod/account.hcl
```

Add:

- Remote state naming convention.
- Generated AWS provider with assume-role.
- One network stack and one app stack.
- A dependency from app to network.

Do not overbuild the modules. The exercise is about live wiring.

### Exercise 4: Policy gate

Write a policy rule in plain English, then implement a small OPA or Sentinel-like pseudocode check for one of:

- RDS encryption required.
- No public SSH security group rule.
- Required tags on production resources.
- S3 public access block required.

Then write the failure message a developer should see in the PR.

---

## 13. Mini project: Complete GitOps workflow

Use the existing `project/` folder for this module. Do not replace the project; extend it as your implementation area.

Goal: design and implement a complete GitOps workflow for a Terraform or OpenTofu AWS stack.

### Project steps

1. Inspect `modules/11-ecosystem/project/`.
2. Choose one automation model:
   - Atlantis.
   - Terraform Cloud.
   - Spacelift.
   - GitHub Actions or another CI runner.
3. Create or update a workflow document in the project folder that explains:
   - Repository layout.
   - State backend.
   - Plan trigger.
   - Apply trigger.
   - Approval requirements.
   - AWS role assumption flow.
4. Add example configuration for the chosen workflow:
   - `atlantis.yaml`, or
   - Terraform Cloud workspace configuration, or
   - Spacelift stack configuration, or
   - CI workflow YAML.
5. Add Infracost commands or integration.
6. Add at least two policy/security checks.
7. Add a production change-management checklist.
8. Add a rollback plan for failed applies.
9. Add a drift detection plan.
10. Write a README section that explains when your workflow should be revisited.

### Expected deliverables

- Architecture diagram.
- Configuration snippets.
- Credential design.
- Plan/apply lifecycle.
- Troubleshooting guide.
- Decision record explaining why you chose the tool.

### Review checklist

- Could a new engineer understand how to ship a safe infrastructure change?
- Are production applies impossible from a laptop?
- Is the plan attached to review?
- Are cost and policy checks visible before approval?
- Is there a clear owner for each stack?

---

## 14. Interview Q&A with answers

1. **What problem does Terragrunt solve that Terraform modules alone do not?**
   Terraform modules package infrastructure logic. Terragrunt manages repeated live configuration around many root modules, such as backend settings, provider generation, account variables, and dependency outputs.

2. **How does Atlantis prevent two applies from racing each other?**
   Atlantis uses project locks so competing PRs cannot apply the same project simultaneously. Terraform backend locking still protects state writes during the actual apply.

3. **What is the difference between remote state and remote execution?**
   Remote state stores Terraform state in a shared backend. Remote execution runs Terraform on a controlled runner instead of a laptop. You can have remote state without remote execution.

4. **Why might an enterprise choose Spacelift over a simple GitHub Actions workflow?**
   Spacelift provides stack dependencies, policy stages, drift detection, private workers, RBAC, audit logs, and multi-IaC orchestration that would otherwise need to be built and maintained.

5. **What are the migration considerations for OpenTofu?**
   Validate provider and module compatibility, pin versions, test state access, confirm automation-platform support, avoid combining migration with provider upgrades, and keep state backups before production applies.

6. **Where should cost estimation happen in a GitOps workflow?**
   After plan generation and before approval. The estimate should be posted to the PR so reviewers can see cost delta alongside resource changes.

7. **How would you design credentials for dev, staging, and prod CI runners?**
   Use OIDC to assume short-lived roles. Keep separate roles per account and environment. Restrict production role assumption to protected branches, approved workflows, and the IaC platform identity.

8. **What policy checks would you require before applying production Terraform?**
   Encryption for data stores, no public administrative ingress, required tags, approved regions, restricted IAM wildcards, backup settings for critical data, logging enabled, and no unapproved destroys.

9. **When is Atlantis a better fit than Terraform Cloud?**
   When you need self-hosted PR automation, private network access, lower platform lock-in, or full control over the runner, and your team can operate the service safely.

10. **How do run tasks differ from static security scans?**
    Static scans inspect HCL or plan content directly. Run tasks are lifecycle integrations that call external systems during a managed run and can return pass, fail, or advisory results.

11. **Why can Infracost numbers differ from the AWS bill?**
    The AWS bill includes real usage, discounts, taxes, support, regional data transfer, shared resources, and negotiated pricing. Infracost estimates based on configuration and usage assumptions.

12. **What is a common Terragrunt anti-pattern?**
    Moving too much resource decision logic into `terragrunt.hcl`. Terragrunt should wire live stacks; Terraform modules should contain infrastructure behavior.

---

## 15. Real-world case study

### Situation

A SaaS company has grown from one AWS account to 14 accounts. It has 90 Terraform roots across networking, data stores, ECS services, CloudFront, WAF, and observability. Engineers run `terraform plan` from laptops. Some roots use local state, some use S3, and state keys are inconsistent. Finance complains that NAT gateways and RDS changes appear without warning. Security needs proof that production changes are reviewed.

### Failure modes

- Local laptops hold broad AWS credentials.
- Plans are not consistently attached to pull requests.
- State layout is inconsistent, making imports and drift response slow.
- Production applies can happen without approval.
- Cost impact is discovered after deployment.
- Shared modules are changed without knowing which stacks are affected.

### Target design

```text
GitHub PR
  |
  v
Atlantis in shared-services account
  |
  +--> terraform fmt/validate
  +--> tflint/trivy
  +--> terraform plan
  +--> Infracost estimate
  +--> OPA policy check
  v
PR comments and required checks
  |
  v
Approved apply through Atlantis
  |
  v
Assume target account role -> S3 state + DynamoDB lock -> AWS APIs
```

The company chooses Atlantis because private network access is required and the platform team already operates Kubernetes. It adds Terragrunt only for live account, region, provider, and backend wiring. It adds Infracost in advisory mode for one month, then requires FinOps approval for monthly deltas above an agreed threshold. Policy checks begin with high-confidence rules: no public SSH, RDS encryption, required tags, and no production destroys without explicit approval.

### Rollout plan

1. Inventory every root module, state backend, and owner.
2. Move local state to S3 with DynamoDB locking.
3. Standardize live folder paths and state keys.
4. Introduce Terragrunt root include for provider and backend generation.
5. Deploy Atlantis in the shared-services account.
6. Start with staging plans only.
7. Add production plans after two weeks of clean staging usage.
8. Remove local production assume-role permissions.
9. Add Infracost comments.
10. Add mandatory policy checks after false positives are resolved.
11. Schedule weekly drift detection for high-risk stacks.

### Outcome

After three months, production changes are reviewed in PRs, state locks are consistent, cost deltas are visible before approval, and CloudTrail shows that production infrastructure changes come from the automation role. The team still has incidents, but the incidents are easier to investigate because the path from code review to apply is auditable.

### Lessons learned

- Standardize state before adding sophisticated policy.
- Do not introduce every tool in one sprint.
- Use advisory checks before blocking production.
- Keep the workflow boring and visible.
- The best ecosystem choice is the one your team can operate during an incident.
