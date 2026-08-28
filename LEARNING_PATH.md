# Terraform Complete Course Learning Path

This path is designed for engineers who know AWS, Linux, Docker, and backend systems and want to become production-ready with Terraform. It is organized by focus area instead of calendar days because people learn at different speeds and teams have different amounts of practice infrastructure available.

Use the readiness criteria honestly. If you cannot explain a phase out loud and complete its checkpoint without copying blindly, stay in that phase longer.

---

## How to use this course

Recommended loop for each module:

1. Read the module README once without touching code.
2. Re-read the sections with HCL examples and diagrams.
3. Complete the exercises.
4. Build or extend the module project.
5. Run `terraform fmt`, `terraform validate`, and a plan where credentials are available.
6. Write down what surprised you.
7. Answer the module interview questions out loud.

Production Terraform skill is a combination of:

- Language fluency.
- AWS architecture judgment.
- State safety.
- Review discipline.
- Debugging ability.
- Operational humility.

---

## Phase 1: IaC and Terraform fundamentals

Primary modules:

- `modules/01-iac-fundamentals`
- `modules/02-terraform-basics`

Estimated focus areas:

- Infrastructure as Code mental model.
- Declarative vs imperative workflows.
- Terraform init, plan, apply, destroy.
- Providers, resources, data sources.
- HCL variables, locals, outputs.
- State basics.
- AWS provider authentication.

Checkpoint work:

- Create a small AWS resource such as an S3 bucket or security group.
- Explain what Terraform stores in state.
- Run `terraform plan` and describe every proposed action.
- Destroy the practice resource safely.
- Complete the module exercises.

You are ready to advance when:

- You can explain `init`, `plan`, `apply`, and `state` without notes.
- You know why state files should not be committed.
- You can read simple HCL and predict the resulting AWS API intent.
- You check plans before applying instead of treating Terraform as a black box.

---

## Phase 2: HCL fluency and safe composition

Primary modules:

- `modules/03-intermediate`
- `modules/05-modules`

Estimated focus areas:

- `count` vs `for_each`.
- Dynamic blocks.
- For expressions.
- `jsonencode`.
- Variable validation.
- Module inputs and outputs.
- Stable module interfaces.
- Examples and module documentation.

Checkpoint work:

- Convert a repeated resource from copy-paste to `for_each`.
- Build a reusable module with variables, outputs, validation, and examples.
- Use `jsonencode` for an IAM policy or ECS container definition.
- Add a README that explains the module contract.

You are ready to advance when:

- You prefer stable keys with `for_each` for named infrastructure.
- You can explain when a module is useful and when it is premature.
- You can design module inputs that do not expose internal implementation details.
- You understand how a bad module interface creates long-term migration pain.

---

## Phase 3: State, collaboration, and refactoring

Primary modules:

- `modules/04-state-management`
- Appendix: `appendices/cheatsheet.md`

Estimated focus areas:

- S3 backend and DynamoDB locking.
- State isolation by environment and stack.
- State commands.
- Import blocks.
- Moved blocks.
- Drift detection.
- Backend migration.
- Lock troubleshooting.

Checkpoint work:

- Configure a remote S3 backend with locking.
- Import one existing resource into Terraform.
- Refactor a resource address using a moved block.
- Simulate a plan review where a replacement appears.
- Explain how to recover from a stuck lock.

You are ready to advance when:

- You treat state operations as production changes.
- You can move a resource into a module without recreation.
- You know the difference between importing, moving, and recreating.
- You can explain why one giant state file is risky.

---

## Phase 4: AWS infrastructure patterns

Primary modules:

- `modules/06-aws-infrastructure`
- `modules/07-production`

Estimated focus areas:

- VPC design.
- Public, private app, and private data subnets.
- Security groups and routing.
- ALB and ECS (overview; dedicated ECS is Module 13).
- RDS.
- Redis.
- CloudWatch logs and alarms.
- Production defaults.
- Pointer: after Module 12, Modules 13–15 go deep on ECS, EKS, and Glue.

Checkpoint work:

- Build or review a VPC with at least two Availability Zones.
- Deploy an ECS-style service pattern in private subnets.
- Add RDS with encryption, backups, and deletion protection.
- Add log groups and alarms with intentional retention.
- Explain the traffic path from a user to a private task.

You are ready to advance when:

- You can draw a production service architecture in ASCII.
- You know why data stores belong in private subnets.
- You can identify which Terraform changes are high risk.
- You include monitoring, logging, and backup in the initial design.

---

## Phase 5: Security, policy, and testing

Primary modules:

- `modules/08-security`
- `modules/09-testing`

Estimated focus areas:

- IAM least privilege.
- Secrets handling.
- OIDC and short-lived credentials.
- Static IaC scanning.
- Policy as code.
- Terraform validation and tests.
- CI quality gates.
- Plan review discipline.

Checkpoint work:

- Add variable validation to a module.
- Run at least one IaC scanner.
- Write a policy rule for public SSH, public S3, missing encryption, or required tags.
- Design CI credentials using OIDC role assumption.
- Build a production apply checklist.

You are ready to advance when:

- You can explain why static access keys in CI are risky.
- You can separate sensitive values from Terraform configuration.
- You know which checks should be advisory and which should block production.
- You can review a plan for security impact, not just syntax.

---

## Phase 6: Advanced Terraform and platform internals

Primary modules:

- `modules/10-advanced`

Estimated focus areas:

- Terraform dependency graph.
- Lifecycle arguments.
- Preconditions and postconditions.
- Provider behavior.
- Custom provider concepts.
- Advanced refactoring.
- Debugging provider and graph issues.

Checkpoint work:

- Explain why Terraform wants to replace a resource.
- Add lifecycle protection to a stateful resource.
- Use preconditions to encode a safety rule.
- Investigate a provider-related plan difference.
- Explain when a custom provider is justified.

You are ready to advance when:

- You can debug a surprising plan systematically.
- You know when lifecycle settings reduce risk and when they hide problems.
- You can explain Terraform's graph-based execution model.
- You can discuss provider limitations without blaming "Terraform magic."

---

## Phase 7: Ecosystem and GitOps delivery

Primary modules:

- `modules/11-ecosystem`

Estimated focus areas:

- Terragrunt.
- Atlantis.
- Terraform Cloud.
- Spacelift.
- OpenTofu.
- Infracost.
- GitOps workflows.
- Run tasks.
- Private registries.
- OIDC for automation.

Checkpoint work:

- Design a PR-based plan/apply workflow.
- Choose between Atlantis, Terraform Cloud, Spacelift, or plain CI for a scenario.
- Add cost estimation to the workflow.
- Decide whether Terragrunt is justified for a multi-account repository.
- Complete the module mini project in `modules/11-ecosystem/project/`.

You are ready to advance when:

- You can explain the difference between remote state and remote execution.
- You can choose a tool based on failure modes, not marketing features.
- You can design credentials so production applies do not run from laptops.
- You understand the operational burden of the platform you choose.

---

## Phase 8: Enterprise AWS architecture

Primary modules:

- `modules/12-enterprise`

Estimated focus areas:

- Multi-account landing zones.
- AWS Organizations and Control Tower.
- SCPs and guardrails.
- Security, logging, networking, shared services, staging, and production accounts.
- Cross-account providers and role assumption.
- Transit Gateway.
- Enterprise tagging.
- Backup and DR.

Checkpoint work:

- Create an account ownership map.
- Draw a landing zone with management, networking, logging, security, shared services, staging, and production accounts.
- Write provider aliases for at least three accounts.
- Design a production ECS/RDS/Redis/CloudFront/WAF stack.
- Choose a DR strategy from RTO/RPO.
- Complete the mini project in `modules/12-enterprise/project/accounts/`.

You are ready to advance when:

- You can explain what Terraform owns in each account.
- You know how SCPs can block Terraform even when IAM allows an action.
- You can design a cross-account role pattern without long-lived production keys.
- You can connect DR choices to RTO, RPO, cost, and operational complexity.

---

## Phase 9: AWS ECS

Primary modules:

- `modules/13-aws-ecs`

Estimated focus areas:

- Cluster, task definition, and service.
- Fargate vs EC2 launch type.
- Task execution role vs task role.
- ALB with `target_type = ip`.
- Private tasks, NAT, and VPC endpoints.
- Circuit breakers and autoscaling.
- When ECS is a better default than EKS.

Checkpoint work:

- Trace `execution_role_arn` and `task_role_arn` in the project.
- Explain the lab public-IP shortcut vs production private tasks.
- Add CPU target-tracking autoscaling in a plan-only change.
- Answer why Fargate target groups must use IP targets.

You are ready to advance when:

- You can draw ALB → Fargate task → logs without notes.
- You refuse to put application S3 permissions on the execution role.
- You know why `:latest` and missing egress both look like "Terraform is broken."
- You can explain ECS vs EKS as an operational choice, not a fashion choice.

---

## Phase 10: AWS EKS

Primary modules:

- `modules/14-aws-eks`

Estimated focus areas:

- Control plane vs node groups / Fargate / Karpenter.
- Cluster IAM, node IAM, and IRSA.
- Kubernetes subnet tags and pod IP capacity.
- Access entries vs `aws-auth`.
- What Terraform owns vs kubectl/CI.
- Optional: GitHub Actions monorepo lab in `project-cicd/`.

Checkpoint work:

- Plan `modules/14-aws-eks/project` without applying.
- List what is missing when `enable_node_group = false`.
- Compare `project/` to the `project-cicd/` VPC/EKS skeleton.
- If you do the CI/CD lab: trace a Flask-only PR through `ci.yml`.

You are ready to advance when:

- You can explain IRSA as the EKS analogue of an ECS task role.
- You will not apply an EKS control plane and forget it over a weekend.
- You split cluster state from application Deployments.
- You can choose ECS (Module 13) when Kubernetes is not a requirement.

---

## Phase 11: AWS Glue jobs

Primary modules:

- `modules/15-aws-glue-jobs`

Estimated focus areas:

- AWS Glue ETL jobs versus crawlers and the Data Catalog.
- A single `aws_glue_job` before the many-job pattern.
- One Terraform root for many jobs with `for_each`.
- YAML job catalogs and generated tfvars.
- Skipping a job in a stage without a second stack.
- S3 script artifacts versus embedding Spark in HCL.
- GitHub Environments, OIDC, and branch-to-account mapping.
- Selective `-target` plans that do not destroy unchanged jobs.

Checkpoint work:

- Explain one Glue job in HCL without opening the YAML lab.
- Generate tfvars for `dev` and `qa` and explain the skip output.
- Add a job folder without editing `main.tf`.
- Trace `customer-etl` prod workers and Glue version from YAML.
- Design separate IAM roles for CI versus Glue runtime.
- Complete the mini project in `modules/15-aws-glue-jobs/exercises/`.

You are ready to advance when:

- You can explain why omitting a job from tfvars destroys it.
- You know what Terraform should own for Glue and what belongs in Git/S3.
- You can map four GitHub Environments onto four AWS accounts without
  hardcoding account IDs in the workflow.
- You treat Glue worker counts as a cost control, not a default of 10.

---

## Phase 12: Capstone and interview readiness

Primary materials:

- `capstone/`
- `appendices/interview-master-list.md`
- `appendices/glossary.md`
- `appendices/resources.md`
- `appendices/cheatsheet.md`

Estimated focus areas:

- End-to-end architecture.
- Tradeoff explanations.
- Production review.
- Incident and drift scenarios.
- Migration planning.
- Interview storytelling.

Checkpoint work:

- Build or review a complete Terraform architecture from VPC to application edge.
- Write a design document that includes state, credentials, environments, CI/CD, security, cost, and DR.
- Practice the interview master list out loud.
- Perform a mock plan review and identify risks.
- Explain a migration from manual AWS or single-account Terraform to a multi-account GitOps workflow.

You are ready for production Terraform ownership when:

- You can design state boundaries and account boundaries intentionally.
- You can defend every high-risk production change in a plan.
- You can recover from common state, lock, import, and drift issues.
- You can explain Terraform to application engineers, security reviewers, and finance stakeholders.
- You know when not to use Terraform for a problem.

---

## Ongoing practice habits

- Read every plan.
- Keep changes small.
- Pin providers.
- Commit lock files.
- Prefer short-lived credentials.
- Document state moves and imports.
- Keep module examples working.
- Add monitoring and backup with the resource, not later.
- Run game days for DR.
- Treat manual console changes as exceptions that need reconciliation.

The goal is not to memorize every Terraform argument. The goal is to make infrastructure changes that are understandable, reviewable, recoverable, and safe for the business.
