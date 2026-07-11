data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app"
  description = "Application security group with dynamic ingress rules"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-app-sg"
  }
}

resource "aws_instance" "server" {
  for_each = var.servers

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = each.value.instance_type
  subnet_id                   = local.server_subnet_ids[each.key]
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y httpd
    TOKEN=$(curl -X PUT -s "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    LOCAL_IPV4=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

    cat > /var/www/html/index.html <<HTML
    <!doctype html>
    <html>
      <head><title>${each.key}</title></head>
      <body>
        <h1>${each.key}</h1>
        <p>Role: ${each.value.role}</p>
        <p>Environment: ${var.environment}</p>
        <p>Instance ID: $INSTANCE_ID</p>
        <p>Private IP: $LOCAL_IPV4</p>
      </body>
    </html>
    HTML

    systemctl enable httpd
    systemctl start httpd
  EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Role = each.value.role
  }

  # Uncomment this in production for critical instances where accidental
  # destruction would be worse than a failed plan. Keep it commented for labs
  # so `terraform destroy` can clean up resources.
  #
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_eip" "server" {
  for_each = var.create_elastic_ips ? var.servers : {}

  domain   = "vpc"
  instance = aws_instance.server[each.key].id

  tags = {
    Name = "${local.name_prefix}-${each.key}-eip"
  }
}
