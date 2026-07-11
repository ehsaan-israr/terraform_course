# Operations Runbook

## Daily checks

- Confirm CI plans are green for active pull requests.
- Review CloudWatch alarms and dashboards.
- Check ECS service desired vs running task count.
- Inspect RDS free storage, CPU, and connection count.
- Review WAF sampled requests for unusual patterns.

## Deploying a change

1. Open a pull request with Terraform changes.
2. Wait for fmt, validate, plan, security scan, and optional cost estimate.
3. Review the plan for creates, updates, destroys, and replacement indicators.
4. Apply to dev.
5. Promote to staging and run smoke tests.
6. Apply to prod through the protected workflow/environment.
7. Watch alarms and service metrics for at least one deployment window.

## Incident: elevated 5xx errors

1. Check the `*-alb-5xx` and `*-target-5xx` alarms.
2. Inspect ALB target health.
3. Check ECS service events for task crashes or failed deployments.
4. Review application logs in `/ecs/<name>`.
5. Roll back the task image if the incident began after deployment.
6. Capture timeline, root cause, and follow-up Terraform changes.

## Incident: database pressure

1. Check RDS CPU, storage, connections, and slow query logs.
2. Confirm application connection pooling is healthy.
3. Scale instance class only after identifying whether pressure is sustained.
4. If storage is low, increase allocated storage and verify autoscaling policy in a future improvement.
5. For production restore scenarios, follow the DR section in `PRODUCTION_CHECKLIST.md`.

## Break-glass guidance

- Use break-glass access only for active incidents.
- Record who used it, why, and when it was revoked.
- Reconcile any console changes back into Terraform immediately after stabilization.
