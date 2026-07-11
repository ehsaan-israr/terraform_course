# Module 05 Project - Composing Reusable Modules

This project demonstrates a root module that composes four local child modules:

```text
project/
  main.tf
  variables.tf
  outputs.tf
  modules/
    vpc/
    security-groups/
    ecs/
    rds/
```

## Architecture

```text
+-------------------+
| Root module       |
| environment glue  |
+---------+---------+
          |
          +-------------------+
          |                   |
          v                   v
  +---------------+    +-------------------+
  | vpc module    | -> | security-groups   |
  +-------+-------+    +---------+---------+
          |                      |
          | subnet IDs           | SG IDs
          v                      v
  +---------------+    +-------------------+
  | ecs module    |    | rds module        |
  | cluster/task  |    | private database  |
  +---------------+    +-------------------+
```

## What each module owns

### `modules/vpc`

Creates:

- VPC.
- Public subnets.
- Private subnets.
- Internet gateway.
- Public route table.
- Private route table.
- Optional NAT gateway.

Outputs subnet IDs and VPC ID for other modules.

### `modules/security-groups`

Creates:

- ALB security group.
- App security group.
- Database security group.
- Tier-to-tier ingress and egress rules.

Outputs security group IDs for compute and database modules.

### `modules/ecs`

Creates:

- ECS cluster.
- CloudWatch log group.
- Task execution role.
- Fargate task definition.
- Optional ECS service skeleton.

The service is disabled by default in the root example with `create_service =
false`. Enable it after you have NAT or public image access, an application
image, and load balancer wiring.

### `modules/rds`

Creates:

- DB subnet group using private subnets.
- Encrypted PostgreSQL RDS instance.
- Randomly generated master password.

Warning: the generated password is marked sensitive in outputs, but it is still
stored in Terraform state. Protect the backend.

## Run the example

This example creates billable AWS resources. Review cost before applying,
especially NAT gateways and RDS.

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Apply only in a sandbox account:

```bash
terraform apply
```

Destroy when finished:

```bash
terraform destroy
```

## Learning tasks

1. Open `main.tf` and trace how `module.vpc.private_subnet_ids` flows into the
   ECS and RDS modules.
2. Change `enable_nat_gateway` to `true` and inspect the planned resources.
3. Add a new output from the VPC module for the internet gateway ID.
4. Add validation to ensure subnet CIDR lists match the number of availability
   zones.
5. Set `create_service = true` in the ECS module call and review the additional
   planned resource.
6. Replace the local VPC module source with a pinned Git source in a branch and
   compare the workflow.

## Production improvement ideas

- One NAT gateway per AZ for resiliency.
- ALB module with target groups and listener rules.
- ECS deployment circuit breaker and autoscaling.
- Secrets Manager for database credentials.
- RDS deletion protection and final snapshots in production.
- Module tests in `tests/` or `examples/`.
- Private module registry publishing and versioning.

