data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.cluster_name}-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat([for subnet in aws_subnet.private : subnet.id], [for subnet in aws_subnet.public : subnet.id])
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 14

  tags = local.common_tags
}
