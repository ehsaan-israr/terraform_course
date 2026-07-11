resource "aws_security_group" "alb" {
  name        = "${local.resource_name}-alb"
  description = "Public HTTP access to the application load balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from the internet for the public ALB"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "ALB forwards traffic to ECS tasks"
}

resource "aws_security_group" "app" {
  name        = "${local.resource_name}-app"
  description = "Application task security group"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-app"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "Application traffic from ALB"
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound application traffic"
}

resource "aws_security_group" "database" {
  name        = "${local.resource_name}-db"
  description = "Private database security group"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-db"
  })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from application tasks"
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.resource_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name               = "${local.resource_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "app_s3_access" {
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.app.arn]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.app.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "app_s3_access" {
  name   = "${local.resource_name}-s3-access"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.app_s3_access.json
}

