# Module 06 Exercises - AWS Infrastructure

Use the platform skeleton in `../project` and a sandbox AWS account. Many
resources are billable, so prefer `terraform plan` for most exercises and destroy
anything you apply.

## Exercise 1: Network trace

Trace packet flow for an HTTP request:

```text
Internet -> ALB -> ECS task -> RDS
```

Identify:

- Public subnets.
- Private subnets.
- Route tables.
- Security group rules.

Success criteria: you can explain why the ALB is public and RDS is private.

## Exercise 2: Add HTTPS

Extend the ALB with:

- ACM certificate variable.
- HTTPS listener on port 443.
- HTTP listener redirect to HTTPS.

Success criteria: the Terraform plan shows an HTTPS listener and no public app
task exposure.

## Exercise 3: NAT versus VPC endpoints

Compare two designs for private ECS egress:

1. `enable_nat_gateway = true`
2. VPC endpoints for ECR, CloudWatch Logs, S3, and Secrets Manager

Document cost, resilience, and security tradeoffs.

Success criteria: you can explain when each design is appropriate.

## Exercise 4: Harden RDS

Modify `database.tf` for production:

- `deletion_protection = true`
- `skip_final_snapshot = false`
- customer-managed KMS key
- Multi-AZ enabled

Success criteria: the plan reflects safer database settings and you can explain
the cost impact.

## Exercise 5: Move secrets to Secrets Manager

Replace direct use of `random_password.db.result` in the RDS resource with a
Secrets Manager pattern. Note which values still appear in state.

Success criteria: you understand the difference between storing a secret in
Secrets Manager and managing secret values with Terraform.

## Exercise 6: Add ECS autoscaling

Add target tracking autoscaling for the ECS service using CPU utilization.

Success criteria: the plan includes an autoscaling target and policy tied to the
ECS service.

## Exercise 7: Improve observability

Add:

- ALB target response time alarm.
- RDS CPU alarm.
- ECS running task count alarm.

Success criteria: alarms have meaningful thresholds and treat missing data
intentionally.

## Exercise 8: IAM least privilege review

Review `security.tf` and answer:

- Which role does ECS use to pull images and write logs?
- Which role does application code use?
- Is S3 access scoped to one bucket?
- What permissions would be needed for Secrets Manager?

Success criteria: you can distinguish deployment, execution, and runtime
permissions.

## Exercise 9: Cost review

Before applying, list all resources with recurring cost:

- ALB.
- NAT gateway if enabled.
- Fargate tasks.
- RDS instance and storage.
- CloudWatch logs.

Success criteria: you can explain how to reduce lab cost without breaking the
architecture lesson.

