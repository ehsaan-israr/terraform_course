data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  count = var.enable_node_group ? 1 : 0

  name               = "${local.cluster_name}-node"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  count = var.enable_node_group ? 1 : 0

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  count = var.enable_node_group ? 1 : 0

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  count = var.enable_node_group ? 1 : 0

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "default" {
  count = var.enable_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = [for subnet in aws_subnet.private : subnet.id]
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
    aws_nat_gateway.main,
  ]
}
