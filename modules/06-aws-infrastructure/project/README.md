# Module 06 Project - AWS Platform Skeleton

This project is a cohesive single-root Terraform example for a small production
platform. It is intentionally readable: resources are split by concern instead
of hidden behind modules.

## Files

```text
versions.tf    Provider and Terraform version constraints
providers.tf   AWS provider configuration
variables.tf   Inputs and cost-sensitive defaults
network.tf     VPC, subnets, route tables, optional NAT
security.tf    Security groups and IAM roles
compute.tf     ALB, ECS cluster, task definition, service
database.tf    Private encrypted RDS PostgreSQL
storage.tf     Private encrypted versioned S3 bucket
monitoring.tf  CloudWatch log group and example alarms
outputs.tf     Values useful after apply
```

## Architecture

```text
Internet
   |
   v
+-------------------------+
| Public ALB              |
| public subnets          |
+-----------+-------------+
            |
            v
+-------------------------+          +-----------------------+
| ECS Fargate service     | -------> | CloudWatch log group  |
| private subnets         |          +-----------------------+
+-----------+-------------+
            |
            +-------------> S3 app bucket
            |
            +-------------> Private RDS PostgreSQL

Security:
ALB SG -> App SG -> Database SG
ECS task role -> least-privilege S3 access
```

## Cost warning

This project can create billable resources:

- Application Load Balancer.
- ECS Fargate tasks.
- RDS instance and storage.
- NAT gateway if `enable_nat_gateway = true`.

Use a sandbox account and destroy resources when finished.

## Important networking note

The ECS service runs in private subnets. To actually run tasks that pull images
and publish logs, private subnets need egress through either:

- `enable_nat_gateway = true`, or
- VPC endpoints for ECR, CloudWatch Logs, S3, and related services.

The default leaves NAT disabled to avoid surprise hourly cost. The plan is still
useful for studying resource relationships.

## Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Apply only after reviewing cost:

```bash
terraform apply
```

Destroy when finished:

```bash
terraform destroy
```

## Production hardening checklist

- Add HTTPS listener with ACM certificate.
- Redirect HTTP to HTTPS.
- Use one NAT gateway per AZ or VPC endpoints.
- Use immutable container image tags.
- Store database credentials in Secrets Manager.
- Enable RDS deletion protection and final snapshots.
- Add ECS autoscaling.
- Add WAF for internet-facing applications.
- Encrypt CloudWatch logs with a customer-managed KMS key if required.
- Send alarms to SNS, PagerDuty, or an incident platform.
- Add CloudTrail and AWS Config at the account/organization layer.

## Study prompts

1. Trace traffic from the ALB to ECS to RDS.
2. Explain why the RDS instance is not publicly accessible.
3. Identify which IAM role is used by ECS itself and which role application code
   assumes.
4. Explain why the generated DB password still requires secure state storage.
5. Change `enable_nat_gateway` to `true` and review the additional route and NAT
   resources.

