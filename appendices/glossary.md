# Glossary

**Account vending**: Automated process for creating and baselining cloud accounts, often through AWS Control Tower Account Factory or an internal platform workflow.

**Alias provider**: A second named provider configuration, such as `aws.networking`, used when one root module must work with multiple regions or accounts.

**Apply**: Terraform operation that changes remote infrastructure to match the reviewed plan.

**Atlantis**: Self-hosted pull request automation service that runs Terraform or OpenTofu plans and applies from VCS comments.

**Backend**: Configuration that tells Terraform where state is stored and how locking works.

**Blast radius**: The scope of damage if a change, failure, or credential compromise goes wrong.

**CloudFront**: AWS content delivery network often used in front of S3, ALB, or API origins for TLS, caching, and edge controls.

**Control Tower**: AWS service for creating and governing a multi-account landing zone with guardrails, account vending, and baseline logging.

**Data source**: Read-only lookup of information from a provider, such as an existing VPC, AMI, or caller identity.

**Declarative configuration**: A style where code describes the desired end state rather than each procedural step.

**Dependency graph**: Terraform's internal graph of resources and data sources used to determine safe operation order.

**Drift**: Difference between Terraform configuration/state and real infrastructure.

**DynamoDB locking**: Common AWS state-locking mechanism used with an S3 backend to prevent concurrent state writes.

**EKS**: Amazon Elastic Kubernetes Service. AWS manages the Kubernetes control plane. You manage VPC, nodes or Fargate, IRSA, add-ons, and workloads. Module 14 teaches the cluster; `project-cicd/` is an optional GitHub Actions lab.

**ECS**: Amazon Elastic Container Service. Cluster + task definition + service. Fargate is the course default. Module 13 is the dedicated lesson; later modules reuse the pattern.

**ElastiCache Redis**: AWS managed Redis-compatible service commonly used for cache, sessions, and rate-limiting state.

**Execution role**: IAM role assumed by Terraform automation to manage resources in a target account.

**Expression**: HCL syntax that computes a value, such as `var.name`, `local.tags`, `for` expressions, or function calls.

**For_each**: Terraform meta-argument that creates one resource instance per map or set element with stable keys.

**GitOps**: Workflow where Git pull requests drive infrastructure changes through automated plan, review, and apply stages.

**IRSA**: IAM Roles for Service Accounts on EKS. A pod's service account assumes an IAM role through the cluster OIDC provider. Analogue of an ECS task role.

**Glue job**: AWS managed Spark ETL job. Terraform owns the job resource; YAML and Python scripts live in Git and are uploaded to S3.

**Guardrail**: Preventive or detective control that constrains allowed infrastructure behavior, often from Control Tower, SCPs, or policy as code.

**HCL**: HashiCorp Configuration Language, the syntax used by Terraform and many Terraform-compatible workflows.

**IaC**: Infrastructure as Code; managing infrastructure through version-controlled code rather than manual console actions.

**IAM Access Analyzer**: AWS service that helps identify external access and validate IAM policies.

**Import block**: Terraform 1.5+ configuration block that maps an existing remote object to a Terraform resource address.

**Infracost**: Tool that estimates cloud cost changes from Terraform or OpenTofu plans and commonly comments on pull requests.

**Landing zone**: Multi-account cloud foundation including accounts, networking, identity, logging, and security baselines.

**Local value**: Named expression inside a `locals` block used to simplify or standardize repeated calculations.

**Module**: A collection of Terraform files treated as a reusable unit. A root module is executed directly; child modules are called by other modules.

**Moved block**: Configuration block that tells Terraform an object moved from one state address to another, preventing unnecessary recreation.

**OpenTofu**: Open-source Terraform-compatible IaC engine forked after Terraform's license change.

**Output value**: Value exported by a module for humans, automation, or parent modules to consume.

**Plan**: Preview of the actions Terraform will take to make infrastructure match configuration.

**Policy as code**: Version-controlled rules that evaluate infrastructure configuration or plans, often with Sentinel, OPA, Checkov, tfsec, or Trivy.

**Provider**: Plugin that lets Terraform manage an external API such as AWS, GitHub, Kubernetes, or Datadog.

**Provider lock file**: `.terraform.lock.hcl`, which records selected provider versions and checksums for repeatable installs.

**Remote execution**: Running Terraform in a controlled automation system instead of on a developer laptop.

**Remote state**: Terraform state stored outside the local filesystem, typically in S3, Terraform Cloud, Spacelift, or another shared backend.

**Resource address**: Terraform identifier for a managed object, such as `aws_vpc.main` or `module.network.aws_subnet.private["us-east-1a"]`.

**Root module**: The Terraform configuration directory where `terraform init`, `plan`, and `apply` are run.

**Run task**: External integration invoked during a managed Terraform run, often for cost, security, or compliance checks.

**SCP**: Service Control Policy in AWS Organizations; sets maximum allowed permissions for accounts or OUs.

**Sentinel**: HashiCorp policy as code framework used with Terraform Cloud and Terraform Enterprise.

**Spacelift**: Managed IaC orchestration platform supporting Terraform, OpenTofu, Terragrunt, Pulumi, CloudFormation, Kubernetes, policies, and workers.

**State**: Terraform's record of managed resources and their known attributes.

**State lock**: Mutual-exclusion mechanism that prevents multiple Terraform operations from writing the same state at the same time.

**Targeted apply**: Terraform apply using `-target`; useful for exceptional recovery but risky as a normal workflow because it can bypass full graph intent.

**Terragrunt**: Wrapper around Terraform/OpenTofu that helps keep live configuration, backend settings, provider generation, and stack dependencies DRY.

**Transit Gateway**: AWS network hub service used to connect VPCs, VPNs, Direct Connect, and shared services at scale.

**Variable validation**: Terraform feature that rejects invalid input values before planning or applying.

**VPC endpoint**: Private connection from a VPC to AWS services without public internet routing.

**Workspace**: Terraform state namespace. Useful in some workflows, but many production teams prefer separate root modules per environment.

**Zero trust for CI**: Credential model where automation uses short-lived, scoped identities such as OIDC instead of long-lived cloud access keys.
