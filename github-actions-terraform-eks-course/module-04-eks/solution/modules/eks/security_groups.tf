resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  description = "EKS cluster control plane security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node" {
  name_prefix = "${var.cluster_name}-node-"
  description = "EKS worker node security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster API — nodes connect to control plane on 443
resource "aws_security_group_rule" "cluster_ingress_nodes_443" {
  description              = "Allow nodes to communicate with the cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
}

# Cluster → nodes (kubelet)
resource "aws_security_group_rule" "node_ingress_cluster_kubelet" {
  description              = "Allow cluster control plane to reach kubelets"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

# Node-to-node communication
resource "aws_security_group_rule" "node_ingress_self" {
  description       = "Allow nodes to communicate with each other"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  self              = true
}

# Nodes → cluster API (egress)
resource "aws_security_group_rule" "node_egress_cluster_443" {
  description              = "Allow nodes to reach cluster API"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

# Nodes → internet via NAT (HTTPS for image pulls, etc.)
resource "aws_security_group_rule" "node_egress_https" {
  description       = "Allow nodes outbound HTTPS to internet via NAT"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node_egress_dns_udp" {
  description       = "Allow nodes outbound DNS (UDP)"
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node_egress_dns_tcp" {
  description       = "Allow nodes outbound DNS (TCP)"
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
}
