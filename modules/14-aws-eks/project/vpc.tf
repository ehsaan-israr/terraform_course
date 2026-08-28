locals {
  resource_name = "${var.name}-${var.environment}"
  cluster_name  = local.resource_name

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "14-aws-eks"
  })

  public_subnets = {
    for index, cidr in var.public_subnet_cidrs :
    var.availability_zones[index] => cidr
  }

  private_subnets = {
    for index, cidr in var.private_subnet_cidrs :
    var.availability_zones[index] => cidr
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = local.resource_name
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                                          = "${local.resource_name}-public-${each.key}"
    Tier                                          = "public"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.common_tags, {
    Name                                          = "${local.resource_name}-private-${each.key}"
    Tier                                          = "private"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-nat"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
