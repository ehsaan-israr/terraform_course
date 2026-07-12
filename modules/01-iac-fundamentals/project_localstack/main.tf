# LocalStack has no Amazon Linux catalog. The compose init script registers
# a placeholder AMI named al2023-ami-localstack on container start.
data "aws_ami" "localstack" {
  count = var.localstack_ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["self", "amazon", "000000000000"]

  filter {
    name   = "name"
    values = ["al2023-ami-localstack"]
  }
}

resource "aws_vpc" "local" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-local-vpc"
  }
}

resource "aws_subnet" "local" {
  vpc_id                  = aws_vpc.local.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-${var.environment}-local-subnet"
  }
}

locals {
  ami_id = coalesce(var.localstack_ami_id, try(data.aws_ami.localstack[0].id, null))
}

resource "aws_s3_bucket" "app" {
  bucket = var.bucket_name

  tags = {
    Name = "${var.project_name}-${var.environment}-app"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web"
  description = "Allow HTTP from the internet and SSH from a trusted CIDR"
  vpc_id      = aws_vpc.local.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from trusted CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}

resource "aws_instance" "web" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.local.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y httpd
    TOKEN=$(curl -X PUT -s "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

    cat > /var/www/html/index.html <<HTML
    <!doctype html>
    <html>
      <head><title>Terraform Module 1</title></head>
      <body>
        <h1>Hello from Terraform Module 1</h1>
        <p>This EC2 instance and S3 bucket were provisioned with Terraform.</p>
        <p>Instance ID: $INSTANCE_ID</p>
      </body>
    </html>
    HTML

    systemctl enable httpd
    systemctl start httpd
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}
