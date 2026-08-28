# Module 13 Exercises — AWS ECS

Use the project in `../project`. Prefer `terraform plan` unless you accept ALB
and Fargate cost. Destroy anything you apply.

## Exercise 1: Name the three objects

From `ecs.tf` and the module README, write one sentence each for:

- Cluster
- Task definition
- Service

Success criteria: you can explain which object is versioned and which object
keeps tasks running.

## Exercise 2: Trace IAM

Open `security.tf` and `ecs.tf`.

1. Which role is `execution_role_arn`?
2. Which role is `task_role_arn`?
3. What managed policy is attached to the execution role?
4. What AWS APIs could nginx call today with the task role?

Success criteria: you would not put S3 application permissions on the execution
role.

## Exercise 3: Networking tradeoff

The project defaults to `assign_public_ip = true`.

Write a short comparison:

| Mode | Subnets | Public IP | How images get pulled | Cost |
| --- | --- | --- | --- | --- |
| Lab default | | | | |
| Production | | | | |

Success criteria: you can explain why private tasks fail without NAT or VPC
endpoints.

## Exercise 4: Target type

The ALB target group uses `target_type = "ip"`.

Deliverable: what happens if you change it to `"instance"` while keeping
Fargate? Do not apply; reason from the docs/README.

## Exercise 5: Add autoscaling (plan only)

Add Application Auto Scaling target tracking on ECS CPU, using the snippet in
the module README. Keep `min_capacity` at 1 and `max_capacity` at 3.

Success criteria: `terraform plan` shows an autoscaling target and policy tied
to this service.

## Exercise 6: Execution role for secrets

You want to inject `DB_PASSWORD` from Secrets Manager via the container
`secrets` key.

Deliverable (no AWS required):

- Which role needs `secretsmanager:GetSecretValue`?
- Does the application code need that permission too if it never calls AWS?

## Interview drill

Answer in two minutes each:

1. Execution role vs task role.
2. ECS vs EKS for a single HTTP API with five engineers.
3. Why `:latest` is a production incident waiting to happen.
