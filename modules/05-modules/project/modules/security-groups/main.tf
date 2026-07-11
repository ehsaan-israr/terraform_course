resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Allow HTTP traffic to the load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from approved clients"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "Forward traffic to application tasks"
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "Allow traffic from the load balancer to application tasks"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-app"
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
  name        = "${var.name}-db"
  description = "Allow database traffic from application tasks"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Database traffic from app security group"
}

resource "aws_vpc_security_group_egress_rule" "db_all" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Database outbound traffic for patching and AWS service calls"
}

