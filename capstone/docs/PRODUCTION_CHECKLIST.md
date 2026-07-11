# Production Readiness Checklist

## Terraform workflow

- [ ] Remote state bucket is encrypted, versioned, and access controlled.
- [ ] State locking is configured.
- [ ] Production applies run only through approved CI/CD.
- [ ] Plans are reviewed before apply.
- [ ] Destructive changes require explicit approval.
- [ ] Provider versions are pinned with `~> 5.0`.

## Security

- [ ] ECS tasks run in private subnets.
- [ ] RDS and Redis are not publicly accessible.
- [ ] Security group ingress is least privilege.
- [ ] Secrets are stored in Secrets Manager or injected by CI.
- [ ] WAF is attached to CloudFront.
- [ ] S3 public access is blocked.
- [ ] IAM task role permissions are least privilege.
- [ ] Security scans run on every pull request.

## Reliability

- [ ] ECS desired count is at least 2 for production.
- [ ] RDS Multi-AZ is enabled.
- [ ] Redis has more than one node if cache availability is required.
- [ ] Health checks match the application endpoint.
- [ ] CloudWatch alarms notify an owned channel.
- [ ] Log retention is appropriate for compliance and cost.

## Backup and disaster recovery

- [ ] RDS backup retention matches RPO.
- [ ] Restore from snapshot has been tested.
- [ ] S3 versioning is enabled.
- [ ] Critical buckets have replication if cross-region DR is required.
- [ ] DNS failover strategy is documented.
- [ ] RTO and RPO are approved by the business.

## Cost

- [ ] Infracost or equivalent cost review is available in PRs.
- [ ] NAT gateway, CloudWatch Logs, data transfer, and RDS costs are reviewed.
- [ ] Non-production environments have right-sized capacity.
- [ ] Unused resources are tagged and reviewed.

## Documentation

- [ ] Architecture diagram is current.
- [ ] Runbook is tested.
- [ ] Owners and escalation paths are documented.
- [ ] Known limitations and future improvements are tracked.
