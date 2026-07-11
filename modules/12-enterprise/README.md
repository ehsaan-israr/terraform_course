# Module 12: Enterprise AWS Architecture with Terraform

Enterprise Terraform is about architecture, ownership, security boundaries, and operations. This module designs a multi-account AWS platform and shows how Terraform code should follow those boundaries.

## Learning objectives

By the end of this module you should be able to:

- Explain a multi-account AWS landing zone.
- Separate networking, shared services, security, logging, staging, and production concerns.
- Design Terraform root modules that assume roles into target accounts.
- Describe patterns for VPC, ECS, RDS, Redis, CloudFront, Route53, WAF, monitoring, backup, and disaster recovery.
- Review an enterprise platform design in an interview setting.

## Multi-account architecture

Recommended account boundaries:

- **Management account**: AWS Organizations, Control Tower, account vending. Avoid workloads here.
- **Networking account**: transit gateway, central egress, shared ingress, DNS resolver endpoints, inspection VPCs.
- **Shared services account**: CI runners, artifact registries, golden AMIs, shared ECS/EKS services, internal tooling.
- **Security account**: GuardDuty, Security Hub, IAM Access Analyzer, delegated admin services, security automation.
- **Logging account**: centralized CloudTrail, VPC Flow Logs, ALB logs, WAF logs, S3 access logs, immutable retention.
- **Staging account**: production-like pre-release workloads.
- **Production account**: customer-facing production workloads with stricter approvals and break-glass access.

## Landing zone diagram

```text
                         AWS Organizations
                                |
       +------------------------+------------------------+
       |                        |                        |
 Management              Security OU              Workloads OU
       |                        |                        |
 Account vending      security account       +--------+---------+
 Control Tower        GuardDuty/SecurityHub  |                  |
 SCP baselines        IAM Access Analyzer    staging account    production account
                                                |                  |
                                                |                  |
                                        ECS/RDS/Redis       ECS/RDS/Redis
                                                |                  |
       +----------------------------------------+------------------+
       |
 Infrastructure OU
       |
 +-----+-------------+----------------+
 |                   |                |
 networking account logging account   shared-services account
 TGW, DNS, egress    CloudTrail/S3     ECR, CI runners, tools
```

## Terraform repository pattern

```text
accounts/
  networking/
  shared-services/
  security/
  logging/
  staging/
  production/
modules/
  vpc/
  ecs-service/
  rds/
  redis/
  waf/
  observability/
```

Each account root module should have remote state isolated by account and environment, provider configuration that assumes a role into the target account, minimal account-specific composition, shared modules for repeatable components, and clear ownership.

## Service design patterns

### VPC

Use at least two Availability Zones for production. Split public, private application, and private data subnets. Use `for_each` by AZ, separate route tables per tier, VPC endpoints for private AWS APIs, and flow logs to the logging account.

### ECS

Use ECS Fargate for teams that need containers without managing nodes. Pattern: cluster, task execution role, task role, CloudWatch log group, ALB target group, service security group, autoscaling, and container definitions generated with `jsonencode`.

### RDS

Production RDS should use Multi-AZ, encryption, automated backups, deletion protection, and maintenance windows. Restrict ingress to application security groups and store credentials in Secrets Manager.

### Redis

Use ElastiCache Redis for cache and ephemeral session patterns. Production patterns include private subnet groups, in-transit encryption, auth token, and Multi-AZ replication groups.

### CloudFront, Route53, and WAF

CloudFront should sit in front of ALB or S3 origins for TLS, caching, and edge protection. Route53 owns public DNS. WAF protects CloudFront or ALB with managed rules and rate limits.

### Monitoring

Create monitoring with the service. Include CloudWatch alarms for ALB 5xx, target health, ECS CPU/memory, RDS CPU/storage, Redis CPU/evictions, log retention, dashboards, and SNS or incident integrations.

### Backup and disaster recovery

Define RTO and RPO before choosing technology. Use AWS Backup plans, RDS automated backups, cross-region snapshots, S3 versioning and replication, Route53 failover records, runbooks, and game days.

## Interview questions

1. Why should production and staging live in separate AWS accounts?
2. What belongs in a networking account?
3. How would you structure Terraform providers for multi-account deployments?
4. What controls prevent developers from changing production from local laptops?
5. How do you design RDS backups for a 15-minute RPO?
6. What should be centralized in a logging account?
7. How do WAF and CloudFront change the blast radius of an application vulnerability?
8. How would you migrate a single-account startup platform to a multi-account landing zone?

## Case study

A SaaS company runs all workloads in one AWS account. Developers share admin permissions, logs are scattered, and production incidents are hard to investigate. The company must pass an enterprise customer security review.

Migration path:

1. Create AWS Organizations and baseline SCPs.
2. Stand up logging and security accounts with delegated admin services.
3. Move CI roles to shared services.
4. Build networking account with transit gateway and DNS resolver patterns.
5. Recreate staging and production in separate accounts with Terraform.
6. Migrate data with planned downtime or replication.
7. Remove broad IAM permissions and require PR-based applies.
8. Run disaster recovery and incident response exercises.
