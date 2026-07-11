terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  # Intentionally bad: hardcoded secrets must never be committed to Git.
  db_username = "admin"
  db_password = "DoNotUseThisPassword123!"
}

resource "aws_security_group" "bad_admin" {
  name        = "insecure-admin-sg"
  description = "Intentionally insecure SSH access"
  vpc_id      = "vpc-00000000000000000"

  ingress {
    description = "BAD: SSH open to the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "bad_data" {
  bucket = "example-insecure-data-bucket"
}

resource "aws_iam_policy" "bad_admin" {
  name = "insecure-admin-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "bad_db" {
  name = "insecure/example/db"
}

resource "aws_secretsmanager_secret_version" "bad_db" {
  secret_id = aws_secretsmanager_secret.bad_db.id
  secret_string = jsonencode({
    username = local.db_username
    password = local.db_password
  })
}

