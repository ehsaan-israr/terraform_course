resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

# RDS instances are billable. Keep this small for education and review cost
# before applying in a real account.
resource "aws_db_instance" "this" {
  identifier = "${var.name}-db"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = var.skip_final_snapshot

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

