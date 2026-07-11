# Capstone Architecture

## Request flow

```text
User Browser
   |
   v
Route53 public hosted zone
   |
   v
CloudFront distribution
   |
   v
AWS WAF managed rules
   |
   v
Application Load Balancer in public subnets
   |
   v
ECS Fargate service in private subnets
   |
   +--> RDS PostgreSQL in private subnets
   +--> ElastiCache Redis in private subnets
   +--> S3 assets bucket
   +--> Secrets Manager for secret references
   +--> CloudWatch logs, metrics, dashboards, and alarms
```

## Module responsibilities

| Module | Responsibility |
| --- | --- |
| `networking` | VPC, public/private subnets, IGW, NAT, route tables |
| `compute-ecs` | ECS cluster, Fargate task/service, ALB, target group, IAM roles, logs |
| `database` | RDS PostgreSQL, DB subnet group, database security group |
| `cache` | ElastiCache Redis, subnet group, Redis security group |
| `storage` | Private encrypted versioned S3 bucket |
| `security` | KMS key, Secrets Manager secrets, WAF web ACL |
| `cdn` | CloudFront distribution in front of the ALB |
| `dns` | Route53 records |
| `monitoring` | SNS alerts, CloudWatch alarms, dashboard |

## Environment strategy

- **dev**: lower cost, smaller desired count, deletion-friendly settings.
- **staging**: production-like topology with moderate capacity.
- **prod**: higher desired count, Multi-AZ database, longer backups, deletion protection.

Each environment uses its own backend key, variables, and state file.

## Security patterns

- Private subnets host ECS tasks, RDS, and Redis.
- ALB is the only public compute entry point.
- CloudFront enforces HTTPS for viewers.
- WAF managed rules inspect edge traffic.
- Secrets are referenced from Secrets Manager.
- RDS and Redis ingress is restricted to the ECS service security group.
- S3 blocks public access and enables encryption/versioning.

## Cost optimization notes

- NAT gateways are expensive; dev may use one NAT gateway or VPC endpoints depending on learning goals.
- Keep dev RDS and Redis small.
- Use autoscaling in a production extension.
- Add Infracost comments before approval.
- Review CloudWatch log retention and data transfer regularly.

## Backup and DR

- RDS automated backups are controlled by environment variables.
- S3 versioning protects against accidental object overwrite/delete.
- Production should add cross-region RDS snapshots and S3 replication.
- Route53 failover can be added for active-passive recovery.
- Recovery steps must be tested in staging before being trusted in production.
