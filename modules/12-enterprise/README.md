# Module 12: Enterprise AWS Architecture with Terraform

Enterprise Terraform is not just "more Terraform." It is infrastructure design under real organizational constraints: account boundaries, security ownership, network connectivity, auditability, disaster recovery, change control, cost allocation, and teams that must move safely without waiting on one central engineer.

This module designs a production-grade AWS landing zone and shows how Terraform should own each layer. The examples use AWS, but the architectural thinking applies to any cloud: separate blast radius, make ownership explicit, automate the baseline, and keep production changes reviewable.

> Region used in examples: `us-east-1`.

---

## Learning objectives

By the end of this module you should be able to:

- Explain a multi-account AWS landing zone and why enterprises use it.
- Decide what Terraform owns in management, networking, shared services, logging, security, staging, and production accounts.
- Configure cross-account providers and role assumption safely.
- Design VPC, ECS, RDS, Redis, CloudFront, Route53, WAF, monitoring, backup, and DR patterns with Terraform.
- Explain how AWS Control Tower and SCPs interact with Terraform.
- Compare transit gateway connectivity patterns.
- Choose DR strategies based on RTO and RPO.
- Apply naming and tagging standards at enterprise scale.
- Defend an enterprise AWS Terraform architecture in an interview.

---

## 1. Enterprise landing zone mental model

An AWS landing zone is the foundation for accounts, identity, security baselines, networking, logging, and governance. It is where you decide:

- Which accounts exist.
- Which OUs contain those accounts.
- Which security controls are mandatory.
- Where logs go.
- How networks connect.
- How workloads receive identities.
- How Terraform changes are applied and audited.

### Why multi-account?

Separate accounts create hard blast-radius boundaries:

- IAM permissions are scoped by account.
- CloudTrail can show account-specific activity.
- Service quotas and noisy workloads are isolated.
- Billing and cost ownership are clearer.
- Production can have stricter controls than staging.
- Security tooling can be delegated from a central account.

Separate VPCs inside one account are useful, but they are not the same boundary. IAM, CloudTrail, quotas, and many service-level controls are account-scoped.

### Landing zone diagram

```text
                               AWS Organization
                                      |
       +------------------------------+------------------------------+
       |                              |                              |
 Management OU                 Infrastructure OU                 Workloads OU
       |                              |                              |
 management account      +-----------+------------+          +------+------+
 organizations           |           |            |          |             |
 control tower      networking   logging    shared-services staging    production
 account vending    tgw/dns      central     ci/ecr/tools    pre-prod   customer traffic
 scp baseline       egress       audit logs   module registry           strict gates
                                      |
                               Security OU
                                      |
                               security account
                               guardduty/securityhub
                               iam access analyzer
```

### Terraform ownership principle

Terraform should own durable infrastructure and policy. It should not own every operational event.

Good Terraform ownership:

- Accounts and OUs after the account vending model is chosen.
- IAM roles and permission boundaries.
- VPCs, subnets, route tables, endpoints, and transit gateway attachments.
- ECS clusters and services.
- RDS and ElastiCache infrastructure.
- CloudFront, Route53, WAF, certificates.
- CloudWatch alarms and log groups.
- AWS Backup plans and vaults.
- Security Hub, GuardDuty, Config, IAM Access Analyzer settings.

Poor Terraform ownership:

- One-off incident actions.
- Every application deployment if a deployment system already owns it.
- Secrets values that should be rotated outside state.
- Resources created by AWS Control Tower that should remain Control Tower-managed.
- Data-plane records with very high churn unless the team accepts frequent plans.

---

## 2. Account strategy: what Terraform owns in each account

### Management account

Purpose:

- AWS Organizations root.
- Control Tower landing zone administration.
- Account Factory or account vending.
- Organization-wide SCP attachment.
- Delegated administrator registration.

Terraform should own:

- Organization units if not exclusively managed by Control Tower.
- SCP definitions and attachments.
- Delegated admin registrations for Security Hub, GuardDuty, Config, IAM Access Analyzer, and AWS Backup.
- Account vending pipeline configuration if your organization uses Terraform for it.

Terraform should not own:

- Application workloads.
- Shared CI runners.
- Long-lived human admin operations.
- Control Tower-managed resources unless the integration is understood.

Example SCP attachment:

```hcl
resource "aws_organizations_policy" "deny_leaving_org" {
  name        = "DenyLeavingOrganization"
  description = "Prevent member accounts from leaving the organization."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Action = [
        "organizations:LeaveOrganization"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_organizations_policy_attachment" "workloads" {
  policy_id = aws_organizations_policy.deny_leaving_org.id
  target_id = aws_organizations_organizational_unit.workloads.id
}
```

### Networking account

Purpose:

- Transit Gateway.
- Central egress and inspection VPCs.
- Shared Route53 Resolver endpoints.
- Private hosted zone associations when centralized.
- Network firewall or third-party inspection.
- Shared ingress patterns if required.

Terraform should own:

- VPCs used for networking services.
- TGW, route tables, associations, propagations, and RAM sharing.
- Resolver rules and endpoints.
- NAT gateways, egress routing, and inspection routing.
- VPC endpoints for shared services.
- Flow logs to the logging account.

Key risk: a networking account change can affect every workload. Plans must be small and reviewed by network/platform owners.

### Shared services account

Purpose:

- CI/CD runners and IaC automation.
- ECR registries.
- Internal developer tools.
- Private module registry or artifact mirrors.
- Shared DNS zones for internal services.
- Golden AMI/image pipelines.

Terraform should own:

- OIDC providers and CI roles.
- ECR repositories and lifecycle policies.
- Artifact buckets and KMS keys.
- Atlantis, private runners, or worker pools if self-hosted.
- IAM roles that assume into target workload accounts.

Example ECR:

```hcl
resource "aws_ecr_repository" "api" {
  name                 = "platform/api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 50 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 50
      }
      action = {
        type = "expire"
      }
    }]
  })
}
```

### Logging account

Purpose:

- Central immutable log storage.
- Organization CloudTrail destination.
- VPC Flow Logs destination.
- ALB, CloudFront, WAF, and S3 access logs.
- Log archive retention and lifecycle.

Terraform should own:

- S3 log buckets with object ownership, encryption, versioning, lifecycle, and restricted bucket policies.
- KMS keys for log encryption.
- CloudTrail organization trail if not Control Tower-owned.
- CloudWatch log destinations and subscription filters where appropriate.
- AWS Backup vault copies if central vaults are used.

Example central log bucket:

```hcl
resource "aws_s3_bucket" "central_logs" {
  bucket = "example-org-central-logs"
}

resource "aws_s3_bucket_versioning" "central_logs" {
  bucket = aws_s3_bucket.central_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "central_logs" {
  bucket = aws_s3_bucket.central_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.logs.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "central_logs" {
  bucket = aws_s3_bucket.central_logs.id

  rule {
    id     = "archive"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }
  }
}
```

### Security account

Purpose:

- Delegated administrator for security services.
- Central findings aggregation.
- Security automation.
- IAM Access Analyzer.
- GuardDuty, Security Hub, Inspector, Detective, Macie as required.

Terraform should own:

- Delegated admin service configuration.
- Organization-wide enablement for security services.
- Security Hub standards and controls.
- EventBridge rules for findings.
- Security automation Lambda functions.
- Cross-account read roles for security tooling.

Example Security Hub organization admin is usually configured from the management account, then service configuration is managed in the security account. Keep that split clear.

### Staging account

Purpose:

- Production-like validation.
- Integration testing.
- Load testing within safe limits.
- Pre-release verification.

Terraform should own:

- Same patterns as production with smaller sizes where acceptable.
- Isolated data stores with sanitized data.
- Deployment roles and application infrastructure.
- Monitoring similar enough to catch production issues.

Staging should not be a toy. If production uses CloudFront, WAF, RDS Multi-AZ, Redis, and private subnets, staging should exercise those paths unless cost or data rules require a documented exception.

### Production account

Purpose:

- Customer-facing workloads.
- Strict access and change control.
- Highest monitoring, backup, and DR requirements.

Terraform should own:

- Production VPC attachments and endpoints.
- ECS services, ALBs, security groups, autoscaling.
- RDS, Redis, KMS, Secrets Manager metadata, backup plans.
- CloudFront, WAF, Route53 records, ACM certificates.
- CloudWatch alarms, dashboards, log retention, incident integrations.
- IAM roles for application and break-glass access.

Production applies should come from trusted automation, not laptops.

---

## 3. Terraform repository and state layout

Recommended shape:

```text
modules/
  vpc/
  ecs-service/
  rds-postgres/
  redis/
  cloudfront-app/
  waf/
  observability/
  backup/
accounts/
  management/
  networking/
  shared-services/
  logging/
  security/
  staging/
  production/
```

Each account folder should contain root modules organized by lifecycle:

```text
accounts/production/
  00-account-baseline/
  10-network-attachment/
  20-data/
  30-services/
  40-edge/
  50-observability/
```

State naming:

```text
s3://example-tfstate-prod/production/us-east-1/30-services/terraform.tfstate
s3://example-tfstate-network/networking/us-east-1/tgw/terraform.tfstate
```

Backend example:

```hcl
terraform {
  backend "s3" {
    bucket         = "example-tfstate-production"
    key            = "production/us-east-1/30-services/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Production state requirements:

- Encryption with KMS.
- DynamoDB or platform locking.
- Bucket versioning.
- Access logs or CloudTrail data events where required.
- Least-privilege state access.
- Separate state per stack to reduce blast radius.
- Regular state backup process.

---

## 4. Cross-account roles and provider aliases

Terraform should run from a trusted identity and assume roles into target accounts.

### Role chain

```text
IaC platform identity
       |
       | OIDC or platform dynamic credential
       v
shared-services/iac-deployer
       |
       | sts:AssumeRole
       v
target-account/terraform-execution
       |
       v
AWS APIs in target account
```

### Provider aliases

Use aliases when one root module must manage resources in more than one account, such as sharing a TGW from the networking account to production.

```hcl
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::111122223333:role/terraform-execution"
  }
}

provider "aws" {
  alias  = "networking"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::222233334444:role/terraform-execution"
  }
}

provider "aws" {
  alias  = "logging"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::333344445555:role/terraform-execution"
  }
}
```

Pass aliases into modules explicitly:

```hcl
module "tgw_attachment" {
  source = "../../modules/tgw-attachment"

  providers = {
    aws.networking = aws.networking
    aws.workload   = aws
  }

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}
```

Trust policy for target execution role:

```hcl
data "aws_iam_policy_document" "terraform_execution_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::444455556666:role/iac-deployer"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/Automation"
      values   = ["terraform"]
    }
  }
}

resource "aws_iam_role" "terraform_execution" {
  name               = "terraform-execution"
  assume_role_policy = data.aws_iam_policy_document.terraform_execution_trust.json
}
```

Best practices:

- Use separate roles for plan and apply if read-only planning is practical.
- Scope production role assumption to protected branches or managed runs.
- Keep human break-glass roles separate from Terraform roles.
- Log and alert on production role assumption.
- Avoid one organization-wide admin role unless bootstrapping.

---

## 5. Control Tower, SCPs, and Terraform

### Control Tower interaction

AWS Control Tower can create and govern the landing zone:

- OUs.
- Account Factory accounts.
- Guardrails.
- Centralized logging.
- Baseline IAM roles.
- AWS Config resources.

Terraform can still manage infrastructure in those accounts, but ownership boundaries must be explicit.

Good pattern:

```text
Control Tower owns:
  landing zone baseline
  mandatory guardrails
  account vending
  baseline roles/logging/config

Terraform owns:
  workload infrastructure
  optional SCPs
  account-specific IAM roles
  networking and application resources
```

Avoid importing every Control Tower-created resource into Terraform unless your team has a clear reason and understands Control Tower lifecycle behavior.

### SCPs and Terraform

Service Control Policies limit what principals in member accounts can do. SCPs do not grant permissions; they set maximum permissions.

Common SCPs:

- Deny disabling CloudTrail, GuardDuty, Security Hub, or Config.
- Deny leaving the organization.
- Deny creating resources outside approved regions.
- Deny making S3 buckets public.
- Deny deleting KMS keys except through break-glass.
- Deny root user access patterns.

Region deny SCP sketch:

```hcl
resource "aws_organizations_policy" "deny_unapproved_regions" {
  name = "DenyUnapprovedRegions"
  type = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      NotAction = [
        "iam:*",
        "organizations:*",
        "route53:*",
        "cloudfront:*",
        "support:*"
      ]
      Resource = "*"
      Condition = {
        StringNotEquals = {
          "aws:RequestedRegion" = [
            "us-east-1",
            "us-west-2"
          ]
        }
      }
    }]
  })
}
```

SCP troubleshooting:

- If Terraform gets `AccessDenied` despite IAM allowing the action, check SCPs.
- Global services may need exceptions in region-deny policies.
- Control Tower guardrails may create preventive controls that block applies.
- Test SCPs in a sandbox OU before attaching to production.
- Keep emergency break-glass documented, but do not rely on it for normal Terraform.

---

## 6. VPC Terraform patterns

Production VPC design usually includes:

- At least two Availability Zones; three when possible.
- Public subnets for load balancers and NAT gateways.
- Private application subnets for ECS tasks.
- Private data subnets for RDS and Redis.
- VPC endpoints for AWS APIs.
- Flow logs to the logging account.
- Explicit network ACL decision; security groups are usually the primary control.

### CIDR and subnet pattern

```hcl
variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

locals {
  azs = var.availability_zones

  public_subnets = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, idx)
  }

  private_app_subnets = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 20)
  }

  private_data_subnets = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 40)
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "private_app" {
  for_each = local.private_app_subnets

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${var.name}-app-${each.key}"
    Tier = "app"
  }
}
```

### VPC endpoints

Use endpoints to keep AWS API calls off the public internet and reduce NAT dependency:

```hcl
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private_app)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(aws_route_table.private_app)[*].id
}
```

### Flow logs to logging account

```hcl
resource "aws_flow_log" "vpc" {
  log_destination      = var.central_flow_log_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id

  destination_options {
    file_format        = "parquet"
    per_hour_partition = true
  }
}
```

Common mistakes:

- One NAT gateway for production without accepting AZ failure impact.
- Public IP assignment on private subnets.
- Overlapping CIDRs that block future TGW connectivity.
- No VPC endpoints, causing high NAT cost and hidden egress dependency.
- Flow logs created but not delivered due to bucket policy.

---

## 7. Connectivity and Transit Gateway patterns

Transit Gateway (TGW) connects VPCs and on-premises networks at scale.

### Centralized networking pattern

```text
                  networking account
               +----------------------+
               | Transit Gateway      |
               | route tables         |
               +---+-------------+----+
                   |             |
        +----------+--+       +--+----------+
        | prod VPC    |       | staging VPC |
        +-------------+       +-------------+
                   |
             +-----+------+
             | egress VPC |
             | firewall   |
             +------------+
```

### TGW sharing with AWS RAM

Networking account:

```hcl
resource "aws_ec2_transit_gateway" "core" {
  description                     = "core-network"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "core-network"
  }
}

resource "aws_ram_resource_share" "tgw" {
  name                      = "core-tgw"
  allow_external_principals = false
}

resource "aws_ram_resource_association" "tgw" {
  resource_arn       = aws_ec2_transit_gateway.core.arn
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

resource "aws_ram_principal_association" "prod" {
  principal          = var.production_account_id
  resource_share_arn = aws_ram_resource_share.tgw.arn
}
```

Workload account attachment:

```hcl
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids         = var.tgw_subnet_ids
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id

  tags = {
    Name = "${var.environment}-attachment"
  }
}
```

Connectivity patterns:

- **Hub and spoke:** most common; workload VPCs attach to central TGW.
- **Segmented route tables:** prod, nonprod, shared-services, and inspection routes are separated.
- **Central egress:** default route from workload VPCs goes through inspection/egress VPC.
- **Distributed egress:** each VPC has its own NAT and internet controls; simpler blast radius, higher cost.
- **Shared services access:** workloads route to shared internal services through TGW or PrivateLink.
- **PrivateLink:** use for service-provider style access without broad network routing.

Best practices:

- Allocate non-overlapping CIDRs before accounts are created.
- Keep TGW route tables explicit; disable default propagation.
- Model route tables in Terraform with clear names.
- Use separate attachments for inspection paths when needed.
- Test failover routes before incidents.

---

## 8. ECS Terraform patterns

ECS Fargate is a common enterprise default for containerized services that do not need Kubernetes.

### ECS service components

```text
ECR image
  |
  v
ECS task definition
  |
  +--> task execution role
  +--> task role
  +--> CloudWatch log group
  v
ECS service on Fargate
  |
  +--> private subnets
  +--> service security group
  +--> target group
  v
Application Load Balancer
```

Task definition pattern:

```hcl
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.image
      essential = true
      portMappings = [{
        containerPort = 8080
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "app"
        }
      }
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
    }
  ])
}
```

Service pattern:

```hcl
resource "aws_ecs_service" "app" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
```

Autoscaling:

```hcl
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.service_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

Best practices:

- Keep tasks in private subnets.
- Separate execution role from task role.
- Use Secrets Manager or SSM Parameter Store for runtime secrets.
- Use immutable image tags or digests in production.
- Add deployment circuit breaker and health checks.
- Decide whether Terraform owns `desired_count`; deployment systems may adjust it.

---

## 9. RDS Terraform patterns

RDS is stateful and high-risk. Terraform plans touching RDS must be reviewed carefully.

Production baseline:

- Multi-AZ or cluster architecture depending engine.
- Encryption with KMS.
- Automated backups and defined retention.
- Deletion protection.
- Maintenance and backup windows.
- Enhanced monitoring or Performance Insights where useful.
- No public accessibility.
- Ingress only from application security groups.

Example PostgreSQL instance:

```hcl
resource "aws_db_subnet_group" "app" {
  name       = "${var.name}-db"
  subnet_ids = var.data_subnet_ids
}

resource "aws_db_instance" "app" {
  identifier              = var.name
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = var.instance_class
  allocated_storage       = 100
  max_allocated_storage   = 500
  storage_encrypted       = true
  kms_key_id              = var.kms_key_arn
  multi_az                = true
  db_subnet_group_name    = aws_db_subnet_group.app.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false
  backup_retention_period = 14
  backup_window           = "06:00-07:00"
  maintenance_window      = "sun:07:00-sun:08:00"
  deletion_protection     = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.name}-final"

  username = var.master_username
  password = var.master_password

  lifecycle {
    prevent_destroy = true
  }
}
```

Security group:

```hcl
resource "aws_security_group_rule" "app_to_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = var.app_security_group_id
}
```

Credentials pattern:

- Prefer AWS Secrets Manager generated passwords.
- Do not print passwords in outputs.
- Mark variables sensitive.
- Consider RDS IAM auth for supported workloads.
- Rotate credentials outside Terraform if rotation cadence is frequent.

Common mistakes:

- Changing `identifier` and causing replacement.
- Removing `deletion_protection` in the same PR as a destructive change.
- Storing master password in plain state without controls.
- Forgetting final snapshots.
- Applying major version upgrades without a runbook.

---

## 10. Redis / ElastiCache Terraform patterns

Redis is usually used for cache, sessions, rate limits, or ephemeral coordination. Treat it as important but be clear whether it is a system of record.

Production baseline:

- Private subnet group.
- Encryption at rest and in transit.
- Auth token for Redis when required.
- Replication group with automatic failover.
- Security group ingress only from application tasks.
- Parameter group for engine tuning.
- CloudWatch alarms for CPU, memory, evictions, connections, and replication lag.

Example:

```hcl
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name}-redis"
  subnet_ids = var.data_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.name
  description                = "Redis for ${var.name}"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = var.node_type
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token
  snapshot_retention_limit   = 7
}
```

Best practices:

- Do not put Redis in public subnets.
- Size memory with headroom; evictions are often an early warning.
- Decide whether snapshot restore is part of DR.
- If cache data is disposable, document that in the runbook.
- Test failover behavior with the application.

---

## 11. CloudFront, Route53, ACM, and WAF patterns

### Edge architecture

```text
User
 |
 v
Route53 alias
 |
 v
CloudFront distribution
 |
 +--> WAF web ACL
 |
 v
ALB origin in public subnets
 |
 v
ECS tasks in private subnets
```

### ACM certificate for CloudFront

CloudFront certificates must be in `us-east-1`.

```hcl
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "edge" {
  provider          = aws.use1
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.domain_name}"]
}
```

### CloudFront distribution sketch

```hcl
resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  aliases             = [var.domain_name]
  default_root_object = ""
  web_acl_id          = aws_wafv2_web_acl.edge.arn

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.edge.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
```

### Route53 alias

```hcl
resource "aws_route53_record" "app" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app.domain_name
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    evaluate_target_health = false
  }
}
```

### WAF managed rules

```hcl
resource "aws_wafv2_web_acl" "edge" {
  name  = "${var.name}-edge"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedCommon"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-edge"
    sampled_requests_enabled   = true
  }
}
```

Best practices:

- Put WAF in count mode before blocking when introducing rules.
- Separate DNS ownership from application service ownership if needed.
- Keep CloudFront cache policies explicit.
- Log WAF and CloudFront to the logging account.
- Use Route53 health checks for failover records when DR requires DNS failover.

---

## 12. Monitoring and observability patterns

Monitoring should be created with the service, not added weeks later.

Minimum production signals:

- ALB 5xx count and target response time.
- Target group healthy host count.
- ECS CPU, memory, task count, and deployment failures.
- RDS CPU, free storage, connections, replica lag, deadlocks.
- Redis CPU, memory, evictions, replication lag.
- WAF blocked request spikes.
- CloudFront 5xx error rate.
- NAT gateway bytes and error metrics where central egress matters.
- Backup job failures.

Alarm example:

```hcl
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.service_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [var.incident_sns_topic_arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}
```

Dashboard sketch:

```hcl
resource "aws_cloudwatch_dashboard" "service" {
  dashboard_name = var.service_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "ALB 5xx"
          region = "us-east-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      }
    ]
  })
}
```

Best practices:

- Route alarms to owned incident channels.
- Use severity levels and avoid paging on noisy symptoms.
- Create dashboards from modules so every service has a baseline.
- Set log retention intentionally; infinite retention is not free.
- Centralize security and audit logs separately from application logs.

---

## 13. Backup and disaster recovery

DR starts with business requirements:

- **RTO:** Recovery Time Objective. How quickly must service return?
- **RPO:** Recovery Point Objective. How much data loss is acceptable?

### Backup patterns

AWS Backup plan:

```hcl
resource "aws_backup_vault" "prod" {
  name        = "prod-vault"
  kms_key_arn = var.backup_kms_key_arn
}

resource "aws_backup_plan" "prod" {
  name = "prod-daily"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.prod.name
    schedule          = "cron(0 6 * * ? *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }
  }
}

resource "aws_backup_selection" "prod" {
  name         = "prod-tagged"
  plan_id      = aws_backup_plan.prod.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}
```

RDS snapshot copy:

```hcl
resource "aws_db_instance_automated_backups_replication" "prod" {
  source_db_instance_arn = aws_db_instance.app.arn
  kms_key_id             = var.dr_region_kms_key_arn
  retention_period       = 14
}
```

### DR strategies

| Strategy | Description | Typical RTO | Typical RPO | Cost | Terraform role |
| --- | --- | --- | --- | --- | --- |
| Backup and restore | Recreate from backups after incident | Hours to days | Hours to day | Low | Define backups, restore runbooks, minimal DR network |
| Pilot light | Minimal core infrastructure always running in DR | Tens of minutes to hours | Minutes to hours | Low to medium | Keep network, security, databases or replicas ready |
| Warm standby | Scaled-down full stack runs in DR | Minutes to hour | Minutes | Medium to high | Maintain parallel stack with smaller capacity |
| Active-active multi-region | Both regions serve traffic | Seconds to minutes | Near-zero to minutes | High | Manage global routing, replication, conflict strategy |

Pilot light diagram:

```text
Primary region                 DR region
-------------                  -------------
full ECS/RDS/Redis             VPC ready
CloudFront/WAF                 minimal ECS capacity
active database                replicated snapshots/read replica
Route53 primary                Route53 failover target
```

Warm standby diagram:

```text
Primary region                 DR region
-------------                  -------------
ECS desired 20                 ECS desired 2
RDS writer                     cross-region replica
Redis cluster                  smaller Redis cluster
Route53 weighted/failover      health-check controlled
```

Best practices:

- Write runbooks before the incident.
- Test restore regularly.
- Store Terraform state and module registry access so DR can run without the primary region.
- Replicate container images and critical artifacts.
- Know which DNS records change during failover.
- Practice failback, not only failover.

---

## 14. Naming and tagging at enterprise scale

Names and tags are operational tools. They support cost allocation, ownership, access review, incident response, and automation.

### Naming convention

Example pattern:

```text
{company}-{environment}-{region-code}-{service}-{component}

acme-prod-use1-payments-api
acme-prod-use1-payments-db
acme-stg-use1-platform-tgw
```

Keep names:

- Predictable.
- Short enough for AWS limits.
- Stable across refactors.
- Free of secrets or customer data.

### Required tags

```hcl
locals {
  required_tags = {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application
    ManagedBy   = "terraform"
    Repository  = var.repository
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = local.required_tags
  }
}
```

Tag policy categories:

- Ownership: `Owner`, `Team`, `Application`.
- Cost: `CostCenter`, `BusinessUnit`.
- Operations: `Environment`, `Criticality`, `DataClassification`.
- Automation: `ManagedBy`, `Repository`, `Backup`.
- Compliance: `PCI`, `SOX`, `Retention`.

Best practices:

- Enforce required tags with policy as code.
- Use provider `default_tags`, but still set resource-specific tags where names differ.
- Avoid high-cardinality tags that change every deployment.
- Align tags with AWS Cost Categories and reporting.
- Document exception handling.

---

## 15. Hands-on exercises

### Exercise 1: Account ownership map

Create a table for these accounts:

- management
- networking
- shared-services
- logging
- security
- staging
- production

For each account, list:

1. What Terraform owns.
2. What Terraform does not own.
3. Required state backend.
4. Required approval level.
5. Main operational risk.

Acceptance criteria:

- Management account has no workloads.
- Logging and security responsibilities are separate.
- Production has stricter approval than staging.

### Exercise 2: Cross-account provider design

Write provider configuration for:

- Default provider: production account.
- Alias `networking`: networking account.
- Alias `logging`: logging account.

Then sketch a module call that uses two aliases to create a VPC attachment and flow logs.

### Exercise 3: Production service stack

Design a Terraform root for an ECS service with:

- ALB.
- ECS Fargate service.
- RDS PostgreSQL.
- Redis.
- CloudWatch alarms.
- WAF attached at CloudFront or ALB.
- Required tags.

Write the file layout and the module inputs. You do not need to implement every module.

### Exercise 4: DR decision

Given:

- RTO: 30 minutes.
- RPO: 5 minutes.
- Application uses ECS, RDS PostgreSQL, Redis cache, S3 uploads, and CloudFront.

Choose backup/restore, pilot light, warm standby, or active-active. Explain:

- Required Terraform stacks in DR region.
- Data replication approach.
- DNS failover approach.
- Monthly cost tradeoff.
- Game-day test plan.

---

## 16. Mini project: Enterprise account architecture

Use the existing `project/accounts/` folder for this module. Keep the folder structure and build your design inside it.

Goal: create a complete enterprise AWS landing-zone design document and Terraform skeleton.

### Project steps

1. Inspect `modules/12-enterprise/project/accounts/`.
2. For each account folder, write or update a README section that defines:
   - Account purpose.
   - Terraform ownership.
   - Remote state key pattern.
   - Required providers and aliases.
   - Required approvals.
3. Create a cross-account role design:
   - Shared services IaC role.
   - Target account Terraform execution roles.
   - Trust boundaries.
   - Production restrictions.
4. Add a networking design:
   - CIDR plan.
   - TGW route table segmentation.
   - Central or distributed egress decision.
   - DNS resolver pattern.
5. Add a production workload design:
   - VPC.
   - ECS.
   - RDS.
   - Redis.
   - CloudFront, Route53, WAF.
   - Monitoring.
   - Backup.
6. Add Control Tower and SCP notes:
   - What Control Tower owns.
   - What Terraform owns.
   - Which SCPs are attached to which OUs.
7. Add a DR plan:
   - Strategy.
   - RTO/RPO.
   - Data replication.
   - Runbook summary.
8. Add naming and tagging standards.
9. Add a review checklist for production applies.

### Expected deliverables

- Account-by-account architecture notes.
- Provider alias examples.
- Network connectivity diagram.
- Production service stack skeleton.
- Backup and DR plan.
- Tagging standard.
- Interview-ready explanation of tradeoffs.

### Review checklist

- Are account boundaries clear?
- Can Terraform assume roles without human production credentials?
- Are logs centralized?
- Are security services delegated?
- Does the network design avoid overlapping CIDRs?
- Is DR tied to RTO/RPO instead of vague "high availability" language?

---

## 17. Interview Q&A with answers

1. **Why should production and staging live in separate AWS accounts?**
   Separate accounts isolate IAM, quotas, CloudTrail, billing, and blast radius. Staging can remain production-like without granting staging users or automation paths access to production.

2. **What belongs in a networking account?**
   Transit Gateway, central egress, inspection VPCs, shared Route53 Resolver endpoints, DNS forwarding rules, TGW route tables, and network-level logging.

3. **How would you structure Terraform providers for multi-account deployments?**
   Use a default provider for the primary target account and aliases for other accounts. Each provider assumes an account-specific Terraform execution role. Pass aliases explicitly into modules that manage cross-account resources.

4. **What controls prevent developers from changing production from local laptops?**
   Remove direct production IAM permissions, require OIDC-based CI roles, restrict production role trust to the IaC platform, enforce protected branches and approvals, and alert on unexpected role assumption.

5. **How do SCPs affect Terraform?**
   SCPs set maximum permissions for accounts. Terraform can still receive `AccessDenied` even when the IAM role allows an action. Region denies and security guardrails must include exceptions for required global services.

6. **How do you design RDS backups for a 15-minute RPO?**
   Automated daily snapshots alone are not enough. Use point-in-time recovery, transaction logs, possibly cross-region automated backup replication or read replicas, and test restore. Confirm the engine's actual recovery granularity.

7. **What should be centralized in a logging account?**
   Organization CloudTrail, Config delivery, VPC Flow Logs, ALB logs, WAF logs, CloudFront logs, S3 access logs, and immutable archive buckets with lifecycle policies.

8. **How do WAF and CloudFront change blast radius?**
   CloudFront absorbs edge traffic and hides origin details. WAF can block common attacks and rate-limit before traffic reaches ALB or services. Misconfiguration can also globally affect users, so changes need careful rollout.

9. **When would you choose centralized egress over distributed egress?**
   Centralized egress is useful for inspection, consistent controls, and fewer internet paths. Distributed egress gives VPC-level blast-radius isolation and simpler routing, but costs more and is harder to govern consistently.

10. **What is the risk of one Terraform state for an entire production account?**
    Plans become slow and risky, locks block unrelated teams, a state issue affects everything, and reviewers must understand too much at once. Split by lifecycle and blast radius.

11. **How would you migrate from a single AWS account to a landing zone?**
    Create Organizations, logging and security accounts, baseline SCPs, shared CI roles, networking account, then rebuild or migrate staging and production workloads into separate accounts with planned data migration and DNS cutover.

12. **What is the difference between high availability and disaster recovery?**
    High availability handles expected component failures within normal operation, often within a region. DR handles larger failures such as region loss, account compromise, or major data corruption and requires RTO/RPO-driven plans.

---

## 18. Real-world case study

### Situation

A B2B SaaS company runs all infrastructure in one AWS account. Developers share broad admin access. CloudTrail exists but logs are mixed with application buckets. Production and staging share VPCs. The company is entering enterprise sales and must pass customer security reviews requiring account separation, centralized audit logs, least privilege, backup evidence, and documented DR.

### Target architecture

```text
AWS Organization
  |
  +-- management
  |     +-- Control Tower
  |     +-- SCPs
  |
  +-- security
  |     +-- GuardDuty delegated admin
  |     +-- Security Hub
  |     +-- IAM Access Analyzer
  |
  +-- logging
  |     +-- org CloudTrail bucket
  |     +-- flow logs bucket
  |     +-- WAF/ALB/CloudFront logs
  |
  +-- networking
  |     +-- Transit Gateway
  |     +-- central egress
  |     +-- Route53 Resolver
  |
  +-- shared-services
  |     +-- CI runners
  |     +-- ECR
  |     +-- Terraform automation
  |
  +-- staging
  |     +-- production-like ECS/RDS/Redis
  |
  +-- production
        +-- customer workloads
        +-- strict apply gates
```

### Migration plan

1. Establish AWS Organizations and Control Tower.
2. Create logging and security accounts first.
3. Enable organization CloudTrail, GuardDuty, Security Hub, and Config.
4. Define baseline SCPs in a sandbox OU, then attach to production OUs.
5. Build shared-services account with CI/OIDC and ECR.
6. Build networking account with TGW, resolver endpoints, and egress pattern.
7. Create staging account and deploy a production-like stack with Terraform modules.
8. Run integration tests and load tests in staging.
9. Create production account and deploy network, data, services, and edge stacks.
10. Migrate data using RDS replication or planned snapshot restore.
11. Cut DNS through Route53 with a rollback plan.
12. Remove admin permissions from humans and require PR-based Terraform applies.
13. Run DR game day and document evidence for customers.

### Key Terraform decisions

- State is split by account and stack.
- Production plans are generated only by automation.
- Provider aliases are used only where cross-account actions are required.
- Control Tower resources are not imported unless necessary.
- Modules enforce default tags, encryption, logging, and backup settings.
- RDS uses `prevent_destroy` and deletion protection.
- Edge stack is separated from service stack because DNS and CloudFront have different blast radius.

### Outcome

The company passes the customer security review. More importantly, production incidents become easier to investigate: every infrastructure change links to a pull request, every production role assumption appears in CloudTrail, and logs are retained in a separate account. The platform costs more than the old single-account setup, but the company can now support enterprise customers and safer team growth.

### Lessons learned

- Account boundaries are architecture, not bureaucracy.
- Central logging and security accounts should come before workload migration.
- SCPs must be tested like code.
- DR without restore testing is only a diagram.
- Terraform modules should encode enterprise defaults so teams do not reinvent security in every service.
