# Exercises: Module 12 Enterprise Architecture

## Exercise 1: Account boundary review

Given these resources, place each in the right account: transit gateway, CloudTrail archive bucket, ECR repository, production ECS service, GuardDuty delegated admin, staging RDS, Route53 resolver endpoints.

Deliverable: table with account, reason, and Terraform root path.

## Exercise 2: Provider assume-role pattern

Write a provider block that assumes `TerraformExecutionRole` into account `123456789012` in `us-east-1`.

Explain:

- Who should be allowed to assume that role.
- How CI obtains initial credentials.
- Why production should use a different role from staging.

## Exercise 3: Production readiness review

Review the capstone production environment and identify five improvements before a real launch.

Examples:

- Autoscaling policies.
- VPC endpoints.
- Cross-region backups.
- Blue/green deployments.
- KMS key policies.

Deliverable: prioritized backlog with risk reduction per item.

## Exercise 4: Disaster recovery tabletop

Pick an RTO and RPO for the capstone platform. Write a restore plan for RDS and S3.

Deliverables:

- RTO/RPO statement.
- Restore sequence.
- Validation checks.
- Communication plan.
