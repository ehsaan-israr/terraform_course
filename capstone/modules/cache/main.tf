resource "aws_security_group" "redis" {
  name        = "${var.name}-redis"
  description = "Redis access from application services"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-redis-sg" })
}

resource "aws_security_group_rule" "app_ingress" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  security_group_id        = aws_security_group.redis.id
  source_security_group_id = each.value
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  description              = "Redis from application service"
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis-subnets"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "${var.name}-redis"
  description                = "Redis cache for ${var.name}"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = var.node_type
  num_cache_clusters         = var.node_count
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = var.auth_token != null
  auth_token                 = var.auth_token
  automatic_failover_enabled = var.node_count > 1
  multi_az_enabled           = var.node_count > 1

  tags = var.tags
}
