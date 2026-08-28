# Module 13 Solutions — AWS ECS

These answers correspond to `../exercises/README.md` and use `../project`.

## Exercise 1: Name the three objects

- **Cluster:** A named capacity and namespace that services run in
  (`aws_ecs_cluster.app`).
- **Task definition:** The versioned recipe: image, CPU, memory, IAM, logs
  (`aws_ecs_task_definition.app`). Each change registers a new revision.
- **Service:** The controller that keeps `desired_count` copies running and
  attached to the ALB (`aws_ecs_service.app`).

The task definition is versioned. The service keeps tasks running.

## Exercise 2: Trace IAM

1. `aws_iam_role.ecs_task_execution` — platform role.
2. `aws_iam_role.ecs_task` — application role.
3. `arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy`
   (ECR pull + CloudWatch Logs).
4. Almost nothing. The task role has no inline or attached application policy
   in this lab. Nginx cannot call S3 until you add a task-role policy.

Application data-plane permissions belong on the **task** role.

## Exercise 3: Networking tradeoff

| Mode | Subnets | Public IP | How images get pulled | Cost |
| --- | --- | --- | --- | --- |
| Lab default | Public | `true` | Internet via IGW | No NAT; tasks are reachable if SG allows it (ALB still the intended entry) |
| Production | Private | `false` | NAT gateway(s) or VPC endpoints for ECR/logs/secrets | NAT hourly + data, or endpoint hourly |

Private tasks without NAT or endpoints stay `PENDING` with a cannot-pull-image
stopped reason.

## Exercise 4: Target type

Fargate uses `awsvpc`. The ENI (IP) is registered with the target group.
`target_type = "instance"` expects EC2 instance IDs. The service would fail to
register targets. Keep `"ip"` for Fargate.

## Exercise 5: Add autoscaling

Example to add (for example in `ecs.tf`):

```hcl
resource "aws_appautoscaling_target" "app" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.resource_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

Plan should include both resources. After autoscaling is live, discuss whether
Terraform should `ignore_changes` on `desired_count`.

## Exercise 6: Execution role for secrets

ECS injects `secrets` **before** the app starts, using the **execution** role.
Add `secretsmanager:GetSecretValue` (and KMS decrypt if needed) to the
execution role.

The application needs the same permission on the **task** role only if it calls
Secrets Manager itself at runtime.

## Interview drill

1. Execution role = ECS platform (pull image, write logs, inject secrets).
   Task role = code in the container calling AWS APIs.
2. ECS Fargate is usually the smaller operational load. Choose EKS when you
   need Kubernetes APIs/operators and can staff that platform. Five engineers
   shipping one API rarely need EKS first.
3. `:latest` moves underneath you. Rollbacks, incident review, and two
   environments "on the same tag" become guesswork. Pin a SHA or digest.
