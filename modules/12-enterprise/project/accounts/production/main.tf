resource "aws_ecs_cluster" "workloads" {
  name = "${var.name_prefix}-production-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "applications" {
  name              = "/platform/production/applications"
  retention_in_days = 14
}

resource "aws_db_subnet_group" "placeholder" {
  name       = "${var.name_prefix}-production-db-subnets"
  subnet_ids = var.database_subnet_ids
}

resource "aws_db_instance" "placeholder" {
  identifier              = "${var.name_prefix}-production-app"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = var.database_instance_class
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.placeholder.name
  username                = var.database_username
  password                = var.database_password
  skip_final_snapshot     = true
  backup_retention_period = 14
  deletion_protection     = true
  storage_encrypted       = true
}
