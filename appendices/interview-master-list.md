# Terraform Interview Master List

Use this as a fast review sheet. Strong answers connect Terraform mechanics to production safety: state, blast radius, reviewability, ownership, and recovery.

## Fundamentals

1. **What problem does infrastructure as code solve?**
   It makes infrastructure reproducible, reviewable, versioned, and auditable instead of relying on manual console steps.

2. **What is the difference between declarative and imperative infrastructure management?**
   Declarative configuration describes the desired end state. Imperative scripts describe step-by-step actions.

3. **Explain Terraform plan, apply, and state.**
   State records known infrastructure, plan compares configuration/state/remote APIs to preview changes, and apply executes the approved changes.

4. **Why should Terraform state be protected?**
   State can contain sensitive values and is the source of truth for resource ownership. Corruption or leakage can cause outages or security incidents.

5. **What happens during `terraform init`?**
   Terraform configures the backend, downloads modules, installs provider plugins, and creates or updates dependency metadata.

6. **Why pin provider versions?**
   Provider upgrades can change behavior. Pinning makes plans repeatable and lets teams review upgrades intentionally.

## HCL and modules

7. **How do variables, locals, outputs, and modules work together?**
   Variables are inputs, locals compute reusable internal values, modules package resources, and outputs expose selected values to users or parent modules.

8. **When would you split code into a module?**
   When a pattern is repeated, needs standard defaults, has a stable interface, or should be owned and tested independently.

9. **What makes a module interface stable?**
   Clear required inputs, minimal optional flags, documented outputs, semantic versioning, and no leaking of internal resource details.

10. **How do you handle optional inputs?**
    Use defaults, nullable variables, optional object attributes, validation, and simple conditionals. Avoid a module with dozens of unrelated feature flags.

11. **Compare `count` and `for_each`.**
    `count` indexes by number and can shift addresses when order changes. `for_each` uses stable map or set keys and is usually safer for named resources.

12. **Why use `jsonencode`?**
    It lets Terraform generate valid JSON for IAM policies, ECS container definitions, dashboards, and other APIs without fragile heredoc formatting.

13. **What is a dynamic block?**
    A way to generate repeatable nested blocks from a collection when the provider schema requires blocks instead of arguments.

## State and collaboration

14. **Why use remote state?**
    Teams need shared, durable state with locking and access control. Local state does not support safe collaboration.

15. **How does locking prevent incidents?**
    Locking prevents two Terraform operations from writing the same state at the same time.

16. **What is drift and how do you detect it?**
    Drift is a difference between code/state and real infrastructure. Detect it with scheduled plans, refresh-only plans, managed platform drift checks, or targeted investigation.

17. **When is `terraform state mv` appropriate?**
    When refactoring addresses without changing real infrastructure, such as moving a resource into a module.

18. **When should you use a moved block instead of `state mv`?**
    Use moved blocks for reviewable, repeatable refactors captured in code, especially across teams and CI.

19. **How do import blocks work?**
    They declare that an existing remote object should be associated with a Terraform address during plan/apply.

20. **What do you do if CI cannot acquire a state lock?**
    Check whether another run is active, whether a prior run crashed, backend health, lock table entries, and automation logs. Force unlock only after confirming no operation is running.

## AWS architecture

21. **How would you design a production VPC?**
    Use multiple AZs, public subnets for load balancers/NAT, private app subnets, private data subnets, VPC endpoints, flow logs, and non-overlapping CIDRs.

22. **Why place ECS tasks in private subnets?**
    Tasks should not be directly reachable from the internet. Traffic should enter through controlled load balancers, CloudFront, and WAF.

23. **How should RDS access be restricted?**
    Put RDS in private data subnets, disable public access, allow ingress only from application security groups, encrypt it, and protect credentials.

24. **What production defaults should RDS have?**
    Encryption, backups, Multi-AZ or equivalent, deletion protection, maintenance windows, final snapshots, monitoring, and restricted security groups.

25. **What is the role of Redis in a production architecture?**
    Redis is usually cache or ephemeral session storage. It should be private, encrypted where required, monitored, and not treated as durable storage unless designed that way.

26. **How do CloudFront, Route53, and WAF fit together?**
    Route53 maps names to CloudFront, CloudFront handles edge TLS/caching, and WAF filters malicious or abusive requests before origin.

27. **What logs should be centralized?**
    CloudTrail, Config, VPC Flow Logs, ALB logs, CloudFront logs, WAF logs, S3 access logs, and security service findings.

## Security

28. **How do you manage secrets in Terraform workflows?**
    Avoid putting secret values in code. Use Secrets Manager, SSM Parameter Store, sensitive variables, dynamic credentials, and restricted state access.

29. **What IAM permissions should CI have?**
    CI should assume short-lived, environment-specific roles with least privilege. Production roles should be restricted to approved workflows and protected branches.

30. **Why is OIDC preferred over static cloud keys in CI?**
    OIDC provides short-lived credentials bound to workload identity, reducing key leakage and rotation burden.

31. **What should a security scan catch before apply?**
    Public S3 exposure, public admin ports, unencrypted data stores, overly broad IAM, missing logs, missing tags, and weak network rules.

32. **Why should production applies be gated?**
    Production changes have customer impact. Gates ensure plans are reviewed, policy passes, ownership is clear, and changes are auditable.

33. **What is policy as code?**
    Versioned rules that evaluate infrastructure code or plans, using tools such as Sentinel, OPA, Checkov, tfsec, or Trivy.

## Production operations

34. **What belongs in a Terraform plan review?**
    Unexpected destroys/replacements, IAM broadening, network exposure, provider upgrades, state moves, cost impact, and whether the change matches the PR intent.

35. **A plan wants to replace a production database. What do you do?**
    Stop. Identify the attribute causing replacement, check whether it is intentional, involve owners, verify backups/restore, and split safe preparatory changes from risky migration.

36. **A team manually changed a security group in AWS. How do you respond?**
    Determine urgency, update Terraform or revert the manual change, run a plan, educate the team, and remove permissions or add automation if it recurs.

37. **How do you handle `ignore_changes` responsibly?**
    Use it only when another system intentionally owns that attribute, document why, and avoid hiding important drift.

38. **When is `-target` acceptable?**
    For exceptional recovery or bootstrapping with careful review. It should not be the normal workflow because it can bypass full graph evaluation.

## Testing and quality

39. **What tests make sense for Terraform modules?**
    `terraform fmt`, `validate`, static scans, variable validation, unit-style checks, plan tests, and integration tests for high-value modules.

40. **What does TFLint add beyond `terraform validate`?**
    Provider-aware linting, naming and deprecated argument checks, and custom rules that Terraform validation does not cover.

41. **How do you test a module interface?**
    Create examples, run plans against them, test required and optional inputs, validate outputs, and ensure upgrades preserve expected behavior.

## Advanced Terraform

42. **When would you build a custom provider?**
    When an API must be managed declaratively and no maintained provider exists, or existing providers cannot model required lifecycle behavior.

43. **How do preconditions and postconditions help?**
    They encode assumptions and guarantees close to resources or outputs, failing early when infrastructure does not meet expectations.

44. **What is the risk of one giant root module?**
    Slow plans, large blast radius, lock contention, hard reviews, and difficult ownership boundaries.

45. **What is the risk of too many tiny root modules?**
    Excess orchestration overhead, complex dependencies, noisy pipelines, and hard-to-understand change ordering.

## Ecosystem

46. **What does Terragrunt solve?**
    DRY live configuration, backend/provider generation, hierarchical inputs, dependency outputs, and multi-stack operations.

47. **When would you choose Atlantis?**
    When you want self-hosted PR plan/apply automation and can operate the webhook service, runner, credentials, and storage.

48. **Compare Terraform Cloud and Spacelift.**
    Terraform Cloud is a managed Terraform-focused platform with state, registry, policy, and runs. Spacelift is broader IaC orchestration with multi-tool support, stacks, OPA policies, and workers.

49. **What is OpenTofu?**
    An open-source Terraform-compatible IaC engine forked after Terraform's license change.

50. **Where does Infracost fit in CI/CD?**
    After plan generation and before approval, so reviewers can see cost deltas in the pull request.

51. **What is the difference between remote state and remote execution?**
    Remote state stores state centrally. Remote execution runs Terraform on a managed or controlled runner.

## Enterprise design

52. **Why use multiple AWS accounts?**
    Accounts isolate IAM, blast radius, quotas, logs, billing, and governance boundaries.

53. **What belongs in a security account?**
    Security Hub, GuardDuty, IAM Access Analyzer, delegated admin services, findings aggregation, and security automation.

54. **What belongs in a logging account?**
    Central CloudTrail, Config delivery, VPC Flow Logs, ALB/WAF/CloudFront logs, immutable S3 buckets, KMS keys, and lifecycle rules.

55. **What belongs in a networking account?**
    Transit Gateway, shared DNS resolvers, central egress, inspection VPCs, and network-level route controls.

56. **How do SCPs affect Terraform?**
    SCPs can deny actions even if the Terraform IAM role allows them. Region-deny and security-control SCPs are common causes of `AccessDenied`.

57. **How do you design backup and DR for RDS?**
    Start with RTO/RPO, enable automated backups/PITR, replicate or copy backups cross-region if needed, protect deletion, and test restore.

58. **Pilot light vs warm standby?**
    Pilot light keeps minimal DR infrastructure ready; warm standby runs a scaled-down full stack. Warm standby costs more but recovers faster.

59. **How would you migrate a single-account startup platform to a landing zone?**
    Create organization baselines, logging/security accounts, shared CI roles, networking, then rebuild or migrate staging and production with controlled data and DNS cutovers.

60. **How do you migrate from a monolithic Terraform codebase to modules?**
    Identify stable patterns, extract modules one at a time, use moved blocks or state moves, preserve behavior, and test plans in lower environments before production.

61. **What is the difference between an ECS task execution role and a task role?**
    The execution role is for the platform: pull images, write logs, inject secrets. The task role is for application code calling AWS APIs.

62. **Why must a Fargate ALB target group use `target_type = ip`?**
    Fargate uses `awsvpc`. The load balancer registers the task ENI address, not an EC2 instance ID.

63. **What should Terraform own for AWS Glue jobs?**
    The job resource: name, role, Glue version, workers, timeout, tags, and the S3 URI of the script. Keep Spark code and per-job YAML in Git; upload scripts in CI.

64. **Why generate a full job map if CI only changed one Glue job?**
    Terraform destroys resources missing from configuration. Full tfvars plus `-target` updates one job without deleting the others.

65. **How do you deploy Glue to four AWS accounts from one workflow file?**
    GitHub Environments inject per-stage `AWS_ROLE_ARN` and variables. The workflow stays generic; OIDC assumes the environment's role.

66. **How should a monorepo CI decide what to run?**
    Path filters. A Flask change should not rebuild Go images or plan every Terraform root unless those paths changed.

67. **What does Terraform own on EKS vs the deploy pipeline?**
    Terraform: cluster, VPC/nodes, IAM/IRSA, add-ons. Pipeline: image build, ECR push, rolling the Deployment to a new tag.

68. **Why bind GitHub OIDC trust to an environment name?**
    So the prod role cannot be assumed from a `develop` workflow run. Stolen workflow YAML still cannot use the prod role without matching `environment:prod`.

69. **Why is `git diff` the wrong infrastructure diff?**
    Git shows which files changed. Terraform plan shows how config, state, and AWS APIs disagree. Drift and data-source changes can produce a plan with no useful git diff.

70. **What does dflook `terraform-apply` do with the PR comment?**
    It plans again and applies only if that plan matches the reviewed comment. If AWS or config moved, it fails with `plan-changed` instead of applying a surprise.

71. **When should Terraform CI skip path filters?**
    When the job's job is to ask Terraform whether infrastructure changed. Path filters may still skip *application* builds. Pair filtered Terraform jobs with scheduled `terraform-check`.
