# Module 13 - AWS ECS with Terraform

This module is the dedicated ECS lesson. Earlier modules *use* ECS as a compute
example. Here the goal is that you can explain every moving piece — cluster,
task definition, service, IAM roles, networking, load balancer, logs, and
deployments — without hunting through Module 05, 06, 12, or the capstone.

Read this README first. Then complete the project and exercises.

**Prerequisites:** Modules 04–06 (remote state, modules, VPC/ALB basics).
**Next:** [Module 14 AWS EKS](../14-aws-eks/) if you need Kubernetes; otherwise
continue the core path. Glue is a separate data-plane topic in
[Module 15](../15-aws-glue-jobs/).

## Learning objectives

By the end of this module you will be able to:

- Draw the ECS mental model: cluster → task definition → running task → service.
- Choose Fargate vs EC2 launch type and explain the tradeoff.
- Write a Fargate task definition with `jsonencode` container definitions.
- Separate the **task execution role** from the **task role**.
- Place tasks in private subnets and front them with an ALB.
- Wire CloudWatch logs, secrets, and health checks.
- Add a deployment circuit breaker and CPU autoscaling.
- Explain when ECS is a better default than EKS or Lambda.

## Why ECS gets its own module

Module 05 showed an ECS *Terraform module*. Module 06 put ECS next to RDS and
S3 in a platform skeleton. Module 12 and the capstone assume you already know
the service.

That spread makes ECS hard to learn. One focused module is easier:

```text
ECR image
  |
  v
Task definition          IAM
  |                      |-- execution role (ECS agent: pull image, write logs)
  |                      `-- task role      (your app: S3, Secrets, SQS, ...)
  v
Service (desired count, deploy strategy)
  |
  +--> private subnets + security group
  +--> ALB target group
  +--> CloudWatch log group
  v
Running Fargate tasks
```

## 1. What ECS is

**Amazon Elastic Container Service** runs Docker containers on AWS without you
operating Kubernetes.

Three objects matter:

| Object | What it is | Terraform resource |
| --- | --- | --- |
| **Cluster** | A namespace and capacity pool | `aws_ecs_cluster` |
| **Task definition** | The immutable recipe (image, CPU, memory, IAM, logs) | `aws_ecs_task_definition` |
| **Service** | Keep N copies of that recipe running and connected to a load balancer | `aws_ecs_service` |

A **task** is one running copy of a task definition. You rarely create tasks
by hand in production. The service creates and replaces them.

```text
Cluster "prod"
  |
  +-- Service "api"      desired_count = 2   --> 2 tasks
  +-- Service "worker"   desired_count = 1   --> 1 task
```

One cluster can host many services. Many teams use one cluster per environment
(or per platform) and many services inside it.

## 2. Fargate vs EC2

| | Fargate | EC2 / Auto Scaling capacity |
| --- | --- | --- |
| Who patches the host? | AWS | You (AMIs, SSM, drain) |
| Billing | vCPU + memory per task | Instances whether tasks fill them or not |
| Networking | `awsvpc` (each task gets an ENI) | `awsvpc`, `bridge`, or `host` |
| Best for | Most APIs and workers | GPUs, burst packing, custom daemons |

**Course default: Fargate.** Lower operational load, and the Terraform is
easier to review. Use EC2 capacity when you have a platform team and a reason.

```hcl
resource "aws_ecs_cluster" "app" {
  name = "orders-prod"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
```

Container Insights is worth turning on. CPU/memory/task-count metrics show up
in CloudWatch without extra sidecar work.

## 3. Task definitions

A task definition is versioned. Every `apply` that changes it registers a new
revision (`api:1`, `api:2`, …). The service can track `latest` or a specific
revision.

Fargate requires:

- `requires_compatibilities = ["FARGATE"]`
- `network_mode = "awsvpc"`
- CPU and memory from the [Fargate pairing table](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html) (for example 256 CPU / 512 MiB)

Use `jsonencode` for `container_definitions`. Do not hand-write JSON strings.

```hcl
resource "aws_ecs_task_definition" "api" {
  family                   = "api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${var.image_repository}:${var.image_tag}"
      essential = true
      portMappings = [{
        containerPort = 8080
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])
}
```

Production image tags:

- Prefer a git SHA or digest (`image@sha256:...`), not `:latest`.
- Terraform often owns the *repository* and the *tag variable*. CI builds the
  image and passes the tag in. Mixing "build the Docker image" into the same
  apply that changes the cluster is painful.

## 4. Two IAM roles (the most common interview question)

| Role | Assumed by | Typical permissions |
| --- | --- | --- |
| **Execution role** | The ECS agent / Fargate platform | Pull from ECR, write to CloudWatch Logs, read secrets *to inject them* |
| **Task role** | Your application process | S3, SQS, DynamoDB, Secrets Manager *if the app calls AWS APIs* |

They look similar in HCL because both trust `ecs-tasks.amazonaws.com`. They are
not interchangeable.

```hcl
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "api-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name               = "api-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}
```

Attach extra execution-role statements when you inject Secrets Manager or SSM
into the container with the `secrets` key. The *app* still needs the task role
if it calls those APIs itself.

Pitfall: putting application S3 permissions on the execution role. The app
cannot use them. Put them on the task role.

## 5. Networking

Fargate tasks always use `awsvpc`. Each task gets an ENI in a subnet you choose.

**Production pattern:**

```text
Internet
  --> ALB (public subnets)
        --> tasks (private subnets, no public IP)
              --> RDS / Redis (private data subnets)
```

Private tasks need **egress** to pull images and write logs:

- NAT gateway(s), or
- VPC endpoints for ECR (api + dkr), S3 (ECR layers), CloudWatch Logs, and
  Secrets Manager

Without NAT or endpoints, tasks stay in `PENDING` and you will see "cannot pull
image" in stopped-task reasons.

**Lab shortcut (this module's project):** tasks can use public subnets with
`assign_public_ip = true` so you can skip NAT cost. That is for learning, not
for production.

```hcl
network_configuration {
  subnets          = var.private_subnet_ids
  security_groups  = [aws_security_group.app.id]
  assign_public_ip = false
}
```

Security groups: allow the **app port from the ALB security group**, not from
`0.0.0.0/0`. The ALB is the only public listener.

## 6. Load balancer

HTTP services almost always sit behind an Application Load Balancer.

```hcl
resource "aws_lb_target_group" "api" {
  name        = "api"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip" # required for Fargate / awsvpc
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.http]
}
```

`target_type = "ip"` is mandatory for Fargate. Instance target types are for
EC2 launch type with a different network mode.

Health checks must hit a cheap, unauthenticated path. If they fail, ECS
replaces tasks in a loop and you will think Terraform is broken.

## 7. ECR

Store images in Amazon ECR in the same region as the cluster.

```hcl
resource "aws_ecr_repository" "api" {
  name                 = "api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

The execution role needs `ecr:GetAuthorizationToken` plus pull permissions on
that repository (the AWS managed execution policy covers common ECR pulls).

CI should:

1. Build and push `api:<git-sha>`.
2. Pass that tag into Terraform or `aws ecs update-service` / a deploy pipeline.

Decide **one owner** of `desired_count` and image rollouts. If Terraform always
sets `desired_count = 2` while autoscaling or a deployer changes it, every plan
fights. Common pattern: Terraform creates the service; a pipeline updates the
task definition revision and service, **or** Terraform takes a `image_tag`
variable from CI.

## 8. Logs, secrets, and configuration

Create the log group yourself so retention is not "never expire":

```hcl
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/api"
  retention_in_days = 30
}
```

Non-secret config: `environment` in the container definition.

Secrets: `secrets` with `valueFrom` pointing at Secrets Manager or SSM. That
requires extra execution-role permissions. Values Terraform writes into Secrets
Manager still land in **state**. Prefer the secret to be created elsewhere and
pass the ARN.

## 9. Deployments and autoscaling

Circuit breaker (shown above) stops a bad image from replacing all healthy
tasks and rolls back.

Autoscaling uses Application Auto Scaling, not an ASG:

```hcl
resource "aws_appautoscaling_target" "api" {
  max_capacity       = 8
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "api-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

If autoscaling owns desired count at runtime, do not also hardcode a fighting
`desired_count` in every apply. Teams often ignore `desired_count` drift or use
`lifecycle { ignore_changes = [desired_count] }` after the initial create.

## 10. ECS vs EKS vs Lambda

| Choose | When |
| --- | --- |
| **ECS Fargate** | Containerized services, AWS-centric team, you want less Kubernetes |
| **EKS** | You need Kubernetes APIs, operators, Helm ecosystem, multi-cloud k8s skills |
| **Lambda** | Event-driven, spiky, short work; packaging and timeouts fit |

ECS is the default in this course's platform (Modules 06, 12, capstone) because
it matches most backend-to-platform migrations. EKS is Module 14. They are not
competitors you must pick on day one of a startup; they are different
operational loads.

## 11. Project

`project/` is a **small, readable ECS stack** — not a full platform:

- VPC with public and private subnets
- ALB in public subnets
- Fargate service (public IP optional so the lab works without NAT)
- Execution role + empty-ish task role
- CloudWatch log group and an ALB 5xx alarm

There is no RDS. Module 06 already combined ECS with a database. This project
is only the container path.

```bash
cd modules/13-aws-ecs/project
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan
# terraform apply    # ALB + Fargate are billable; destroy when done
terraform destroy
```

Default image is public nginx so you do not need ECR for the first apply.
Change `assign_public_ip` and subnets after you add NAT or VPC endpoints.

## 12. Production practices

- Private tasks, public ALB only.
- Distinct execution and task roles; no `AdministratorAccess`.
- Immutable image tags / digests.
- Explicit log groups with retention.
- Circuit breaker + health checks on a real `/health`.
- Autoscaling with a documented min/max.
- One cluster per environment is simpler than sharing prod/dev.
- Tag cluster, service, and task definition with owner and service name.

## 13. Common mistakes

1. Tasks in private subnets with no NAT and no VPC endpoints.
2. Swapping execution role and task role.
3. `target_type = "instance"` on a Fargate service.
4. Health check path that requires auth or a database.
5. `:latest` in production.
6. One security group for ALB and tasks.
7. Letting Terraform and a deployer both stomp `desired_count`.
8. Leaving the ALB running after class (hourly cost).

## 14. Interview Q&A

**What is the difference between a task definition and a service?**
The task definition is the versioned recipe. The service is the controller that
keeps a desired number of that recipe running and attached to load balancing.

**Execution role vs task role?**
Execution: platform needs (ECR, logs, secret injection). Task: application AWS
API calls.

**Why `awsvpc` on Fargate?**
Fargate only supports `awsvpc`. Each task gets its own ENI and security group.

**Why might a new service never become healthy?**
Bad image, no egress to ECR, security group does not allow the ALB, health check
path/port mismatch, or the container listens on a different port than
`portMappings`.

**When would you pick ECS over EKS?**
When you want managed containers without running Kubernetes. Pick EKS when the
Kubernetes API and ecosystem are requirements and you can staff that platform.

## 15. Mini case study

A team moved a public EC2 "pet" to ECS Fargate. Order of operations that
worked:

1. VPC + ALB + empty target group (health checks fail until tasks exist).
2. Task definition with a known-good image and logs.
3. Service `desired_count = 1` in staging, public IP off, NAT on.
4. Fix the first `STOPPED` reason (almost always IAM or egress).
5. Add circuit breaker, then autoscaling, then cut DNS.

They did **not** start with EKS. Nothing in the app needed Kubernetes.

## Further reading

- ECS developer guide: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/
- Fargate task CPU/memory: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
- Terraform `aws_ecs_service`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
- Module 06 platform skeleton: [../06-aws-infrastructure/](../06-aws-infrastructure/)
- Module 14 EKS: [../14-aws-eks/](../14-aws-eks/)
