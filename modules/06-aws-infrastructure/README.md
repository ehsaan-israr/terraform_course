# Module 06 - AWS Infrastructure with Terraform

This module connects Terraform language skills to real AWS production
engineering. You will learn how core AWS services fit together, how Terraform
models them, which patterns are common in production, and which pitfalls cause
expensive or risky incidents.

The focus is not memorizing every AWS resource argument. The focus is designing
safe, observable, secure infrastructure that teams can operate over time.

## Learning objectives

By the end of this module you will be able to:

- Design a VPC with public and private subnets, route tables, NAT, security
  groups, and network ACLs.
- Choose between EC2, Auto Scaling Groups, ECS, EKS, and Lambda.
- Model S3, EBS, EFS, RDS, Aurora, DynamoDB, and ElastiCache safely.
- Use IAM, KMS, Secrets Manager, and Parameter Store in Terraform.
- Add monitoring and audit foundations with CloudWatch and CloudTrail.
- Recognize AWS/Terraform pitfalls before they reach production.
- Explain a production-grade platform architecture.

## Production platform architecture

The project in this module builds a readable platform skeleton:

```text
Users
  |
  v
+---------------------+
| Application Load    |
| Balancer            |
+----------+----------+
           |
           v
+---------------------+       +---------------------+
| ECS Fargate service | ----> | CloudWatch Logs     |
| or ASG/EC2 compute  |       +---------------------+
+----------+----------+
           |
           v
+---------------------+       +---------------------+
| Private RDS         |       | S3 app bucket       |
| PostgreSQL          |       | encrypted storage   |
+---------------------+       +---------------------+

Network foundation:

+-------------------------------------------------------------+
| VPC                                                         |
|                                                             |
|  Public subnets                 Private subnets             |
|  +-------------------+          +------------------------+   |
|  | ALB               |          | ECS tasks / EC2        |   |
|  | NAT Gateway       | -------> | RDS                    |   |
|  +-------------------+          +------------------------+   |
|                                                             |
+-------------------------------------------------------------+
```

## 1. Networking

Networking defines the blast radius and communication paths of your platform.
Most AWS outages caused by Terraform mistakes involve networking in some way:
wrong route table, overly broad security group, missing NAT, or resources placed
in public subnets.

### VPCs

A VPC is an isolated network boundary in an AWS region.

Pattern:

- One VPC per environment or platform boundary.
- CIDR blocks chosen from an organization-wide IP plan.
- DNS support and DNS hostnames enabled.
- Tags that identify owner, environment, and cost center.

Terraform snippet:

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "prod-platform"
    Environment = "prod"
  }
}
```

Pitfalls:

- Overlapping CIDRs block VPC peering, Transit Gateway, VPN, and Direct Connect.
- Too-small CIDRs make future subnet expansion painful.
- Changing a VPC CIDR often requires resource replacement or complex migration.

### Subnets

Subnets live in one availability zone. Multi-AZ applications need subnets in
multiple AZs.

Pattern:

- Public subnets for load balancers and NAT gateways.
- Private application subnets for ECS, EKS worker nodes, or EC2.
- Private database subnets for RDS and ElastiCache.
- Consistent CIDR allocation per AZ.

```hcl
resource "aws_subnet" "private" {
  for_each = {
    "us-east-1a" = "10.0.10.0/24"
    "us-east-1b" = "10.0.11.0/24"
  }

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "prod-private-${each.key}"
    Tier = "private"
  }
}
```

Pitfalls:

- Putting databases in public subnets.
- Using `count` indexes and accidentally changing subnet identity when lists are
  reordered. Prefer `for_each` keyed by AZ name.
- Forgetting enough IP capacity for ECS tasks, EKS pods, or Lambda VPC ENIs.

### Route tables, internet gateways, and NAT

Public route table:

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
```

Private route table with NAT:

```hcl
resource "aws_nat_gateway" "az_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public["us-east-1a"].id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az_a.id
  }
}
```

Patterns:

- Production: one NAT gateway per AZ for resilience.
- Cost-sensitive dev: one NAT gateway or VPC endpoints instead.
- Use VPC endpoints for S3, DynamoDB, ECR, CloudWatch Logs, and Secrets Manager
  to reduce NAT dependency.

Pitfalls:

- A single NAT gateway is a single-AZ dependency.
- NAT gateways are billable hourly and per GB.
- Private ECS tasks cannot pull images or send logs without NAT or VPC endpoints.

### Security groups

Security groups are stateful instance-level firewalls.

Pattern: reference security groups instead of CIDRs for tier-to-tier traffic.

```hcl
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
```

Pitfalls:

- Opening SSH/RDP to `0.0.0.0/0`.
- Using one shared security group for every tier.
- Mixing inline rules and separate rule resources, causing rule churn.

### Network ACLs

NACLs are stateless subnet-level controls. Many teams keep default NACLs open
and rely on security groups. Regulated environments may use NACLs as an
additional boundary.

Pattern:

- Security groups for normal application controls.
- NACLs for broad subnet guardrails.
- Document ephemeral port requirements because NACLs are stateless.

Pitfalls:

- Blocking ephemeral response ports.
- Assuming NACLs are stateful like security groups.
- Creating too many low-level deny rules that are hard to reason about.

## 2. Compute

### EC2

Use EC2 when you need VM-level control, specialized agents, custom networking,
or workloads that do not fit containers/serverless.

```hcl
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public["us-east-1a"].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion.name

  metadata_options {
    http_tokens = "required"
  }
}
```

Patterns:

- Use launch templates for repeatable EC2 settings.
- Require IMDSv2.
- Attach IAM roles instead of static credentials.
- Use SSM Session Manager instead of public SSH where possible.

Pitfalls:

- Hard-coding AMI IDs without an update process.
- Putting secrets in user data.
- Managing pets instead of replacing instances.

### Auto Scaling Groups

ASGs keep a desired number of EC2 instances running.

```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
}

resource "aws_autoscaling_group" "app" {
  min_size            = 2
  max_size            = 6
  desired_capacity    = 2
  vpc_zone_identifier = values(aws_subnet.private)[*].id

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
```

Patterns:

- Spread across AZs.
- Use health checks and rolling instance refresh.
- Attach to ALB target groups for web services.

Pitfalls:

- Updating launch templates without triggering instance refresh.
- Desired capacity fights with external autoscaling unless configured carefully.

### ECS

ECS is AWS's managed container orchestrator. Fargate removes the need to manage
EC2 worker nodes. This section is the overview; the dedicated lesson is
[Module 13](../13-aws-ecs/).

```hcl
resource "aws_ecs_cluster" "main" {
  name = "prod"
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.api.id]
  }
}
```

Patterns:

- Use ALB target groups for HTTP services.
- Store secrets in Secrets Manager or SSM Parameter Store.
- Enable CloudWatch logs.
- Add deployment circuit breakers and autoscaling.

Pitfalls:

- Tasks in private subnets without NAT or VPC endpoints.
- Forgetting execution role permissions.
- Using `latest` container tags in production.

### EKS overview

EKS runs Kubernetes control planes managed by AWS. Dedicated coverage is
[Module 14](../14-aws-eks/). This section is only the decision, not the
implementation.

Use EKS when:

- You need Kubernetes APIs and ecosystem.
- You run many services with platform team support.
- You need advanced scheduling, operators, or multi-cloud portability goals.

Patterns:

- Use managed node groups or Karpenter.
- Keep cluster add-ons versioned.
- Use IAM Roles for Service Accounts (IRSA).
- Separate cluster infrastructure from application manifests.

Pitfalls:

- Underestimating operational complexity.
- Mixing Terraform-managed Kubernetes objects with controllers that mutate them.
- Not planning pod IP capacity.

### Lambda

Lambda is event-driven serverless compute.

```hcl
resource "aws_lambda_function" "worker" {
  function_name = "image-worker"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "handler.main"
  filename      = "function.zip"
  timeout       = 30
}
```

Patterns:

- Keep deployment packages versioned.
- Use aliases for safe deployments.
- Set reserved concurrency for blast-radius control.
- Avoid VPC attachment unless required.

Pitfalls:

- Terraform is not always the best packaging tool. Build artifacts in CI and
  pass immutable package paths or image tags to Terraform.
- VPC Lambdas require subnet IP capacity and network egress planning.

## 3. Storage

### S3

S3 is object storage for artifacts, logs, data lakes, backups, and static sites.

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "company-prod-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

Patterns:

- Block public access by default.
- Enable encryption.
- Enable versioning for critical data.
- Use lifecycle rules for cost control.

Pitfalls:

- Globally unique bucket names.
- Accidental public bucket policies.
- Destroying buckets with retained data.

### EBS

EBS provides block storage for EC2.

Patterns:

- Encrypt by default.
- Snapshot important volumes.
- Prefer gp3 for predictable cost/performance.
- Treat instance root volumes as replaceable.

Pitfalls:

- Manual volume modifications drifting from Terraform.
- Not setting delete-on-termination intentionally.

### EFS

EFS provides shared NFS file storage.

Patterns:

- Mount targets in every application AZ.
- Security groups restrict NFS to clients.
- Use access points for application isolation.

Pitfalls:

- Higher latency than local disk.
- Unbounded growth without lifecycle policies.

## 4. Databases

### RDS

RDS manages relational database engines.

```hcl
resource "aws_db_instance" "postgres" {
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
}
```

Patterns:

- Private subnets.
- Encryption.
- Backups and final snapshots.
- Deletion protection in production.
- Secrets Manager for credentials.

Pitfalls:

- `skip_final_snapshot = true` in production.
- Public accessibility.
- Applying engine upgrades without maintenance planning.

### Aurora

Aurora is AWS's cloud-native relational database engine.

Patterns:

- Use clusters with writer and reader instances.
- Consider Serverless v2 for variable workloads.
- Use separate parameter groups for controlled tuning.

Pitfalls:

- Cost surprises from readers and I/O.
- Complex major version upgrades.

### DynamoDB

DynamoDB is managed NoSQL key-value/document storage.

```hcl
resource "aws_dynamodb_table" "sessions" {
  name         = "prod-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }
}
```

Patterns:

- Design access patterns first.
- Use on-demand billing for unpredictable workloads.
- Enable point-in-time recovery for critical tables.

Pitfalls:

- Adding global secondary indexes without understanding write cost.
- Expecting ad hoc relational queries.

### ElastiCache

ElastiCache provides Redis or Memcached.

Patterns:

- Private subnets.
- Security groups from app tier only.
- Multi-AZ replication for production Redis.
- Parameter groups for maxmemory policies.

Pitfalls:

- Treating cache as durable storage.
- No encryption/auth planning.
- Cache node types that are too small for working set.

## 5. Security

### IAM

IAM controls identity and permissions.

Patterns:

- Least privilege policies.
- IAM roles for workloads.
- Separate deployer roles from runtime roles.
- Use policy documents instead of heredoc JSON when possible.

```hcl
data "aws_iam_policy_document" "read_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
  }
}
```

Pitfalls:

- Wildcard actions and resources.
- Long-lived access keys.
- Confusing execution role, task role, and deploy role in ECS.

### KMS

KMS manages encryption keys.

Patterns:

- Use AWS-managed keys for many simple workloads.
- Use customer-managed keys when you need key policy control, rotation, or audit
  boundaries.
- Keep key policies understandable.

Pitfalls:

- Locking administrators out with an invalid key policy.
- Forgetting grants for services that need to encrypt/decrypt.

### Secrets Manager

Secrets Manager stores secrets with rotation support.

Patterns:

- Generate or store database credentials.
- Reference secret ARNs from ECS task definitions.
- Rotate high-value credentials.

Pitfalls:

- Creating secret versions in Terraform for highly dynamic secrets can place
  secret values in state.
- Deleting secrets has a recovery window.

### Parameter Store

SSM Parameter Store stores configuration and lower-complexity secrets.

Patterns:

- Use `String` for non-secret config.
- Use `SecureString` for lower-volume secrets.
- Publish cross-stack values such as VPC IDs instead of exposing remote state.

Pitfalls:

- SecureString values managed by Terraform are still in state.
- API throughput limits for heavy runtime usage.

## 6. Monitoring and audit

### CloudWatch

CloudWatch collects metrics, logs, and alarms.

Patterns:

- Create log groups explicitly with retention.
- Alarm on user-impacting symptoms.
- Use dashboards for operational visibility.

```hcl
resource "aws_cloudwatch_log_group" "app" {
  name              = "/app/prod/api"
  retention_in_days = 30
}
```

Pitfalls:

- Infinite log retention.
- Alarms with noisy thresholds that teams learn to ignore.
- Missing permissions for workloads to write logs.

### CloudTrail

CloudTrail records AWS API activity.

Patterns:

- Organization trail in a security account.
- S3 bucket with versioning and restricted access.
- CloudWatch or EventBridge alerts for high-risk API calls.

Pitfalls:

- Creating only regional trails when global service events matter.
- Storing audit logs in an account where operators can delete them.

## 7. Project: production-grade AWS platform skeleton

The project under `project/` wires together:

- VPC networking.
- Public ALB.
- ECS Fargate service stub.
- Private RDS PostgreSQL instance.
- Encrypted S3 bucket.
- IAM execution roles.
- CloudWatch log group and alarms.

It uses a single-root layout with clear files:

```text
project/
  versions.tf
  providers.tf
  variables.tf
  network.tf
  security.tf
  compute.tf
  database.tf
  storage.tf
  monitoring.tf
  outputs.tf
  README.md
```

This is intentionally readable rather than abstracted into modules. Module 05
showed reusable modules; this module emphasizes how AWS services fit together.

## 8. Interview Q&A

### Q1: Public subnet vs private subnet?

A public subnet has a route to an internet gateway and resources can be directly
reachable if they have public IPs and permissive security rules. A private
subnet does not route directly to an internet gateway; outbound internet access
usually goes through NAT or VPC endpoints.

### Q2: Why use security group references instead of CIDR blocks?

Security group references express tier relationships, such as "app accepts
traffic from ALB", without depending on changing IP addresses. They are safer and
clearer for dynamic compute.

### Q3: Why might private ECS tasks fail to start?

They may lack egress to pull container images, retrieve secrets, or send logs.
Provide NAT gateways or VPC endpoints for ECR, CloudWatch Logs, Secrets Manager,
and S3 as needed.

### Q4: When would you choose ECS over EKS?

Choose ECS when you want managed container orchestration with lower operational
complexity and strong AWS integration. Choose EKS when you need Kubernetes APIs,
operators, or ecosystem compatibility and have the operational maturity to run
Kubernetes.

### Q5: Why is `publicly_accessible = false` not enough for RDS security?

It prevents public endpoint exposure, but you still need private subnet
placement, restrictive security groups, encryption, backups, IAM controls, and
secret management.

### Q6: What is the difference between an ECS task execution role and task role?

The execution role lets ECS pull images and write logs. The task role is assumed
by application code running inside the container to access AWS services.

### Q7: Why create CloudWatch log groups explicitly?

Explicit log groups let you set retention, encryption, tags, and permissions
before workloads start writing logs. Auto-created log groups often default to
never expiring logs.

### Q8: What AWS resources are commonly expensive in Terraform labs?

NAT gateways, RDS instances, load balancers, EKS clusters, ElastiCache clusters,
and large EC2 instances. Always review cost before applying.

### Q9: How do VPC endpoints help production platforms?

They let private workloads reach AWS services without traversing NAT gateways or
the public internet, improving security posture and sometimes reducing NAT data
processing cost.

### Q10: Why should IAM policies be generated with `aws_iam_policy_document`?

The data source produces valid JSON, supports composition, avoids quoting
mistakes, and makes policy intent easier to review than large heredocs.

## 9. Real-world case study: migrating a public monolith to a private platform

### Starting point

A startup runs a monolithic application on one public EC2 instance. The instance
has SSH open to the internet, stores uploads on local disk, connects to a public
RDS database, and writes logs only to files. Deployments involve SSH and shell
scripts.

### Target architecture

The platform team designs:

- VPC with public and private subnets across two AZs.
- ALB in public subnets.
- ECS Fargate service in private subnets.
- RDS PostgreSQL in private database subnets.
- S3 bucket for uploads.
- CloudWatch logs and alarms.
- IAM roles for task permissions.
- Secrets Manager for database credentials.
- SSM Session Manager for rare administrative access.

### Terraform rollout

1. Build network foundation and verify routing.
2. Create ALB and health check endpoint.
3. Create RDS replica/migration target in private subnets.
4. Create S3 bucket and migrate uploads.
5. Deploy ECS service with desired count 1 in staging.
6. Add autoscaling and alarms.
7. Cut production traffic gradually using weighted DNS.
8. Lock down old EC2 security group and decommission after rollback window.

### Lessons

- Network design came first because every later resource depended on it.
- The team avoided public databases and public SSH.
- CloudWatch logs made deployments observable.
- IAM task roles replaced instance credentials.
- Terraform plans were reviewed by platform and application engineers together.
- Cost controls were added early for NAT, ALB, and RDS.

