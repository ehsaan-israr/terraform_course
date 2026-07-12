# Module 04 Solution: Amazon EKS with Terraform

Line-by-line explanation of the EKS module and root composition.

---

## Root `main.tf` — Module Composition

```hcl
module "vpc" {
  source = "./modules/vpc"
  cluster_name = "${local.name_prefix}-eks"
  ...
}
```

Passes `cluster_name` to VPC so subnets receive `kubernetes.io/cluster/<name> = "shared"` tags **before** EKS is created—required for load balancer subnet discovery.

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name       = "${local.name_prefix}-eks"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.vpc]
}
```

Explicit `depends_on` ensures subnets and routing exist before control plane ENI placement.

---

## `modules/eks/iam.tf` — Cluster Role

```hcl
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
```

EKS service assumes this role to manage AWS resources on your behalf.

```hcl
resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
```

Minimum managed policy for control plane operation.

---

## Node Role

```hcl
resource "aws_iam_role" "node" {
  assume_role_policy = jsonencode({
    Principal = { Service = "ec2.amazonaws.com" }
    ...
  })
}
```

EC2 instances in the managed node group assume this role via instance profile (created implicitly by EKS managed node group when `node_role_arn` is set).

Three policy attachments:

- `AmazonEKSWorkerNodePolicy` — kubelet registration
- `AmazonEKS_CNI_Policy` — VPC CNI plugin
- `AmazonEC2ContainerRegistryReadOnly` — pull images from ECR

---

## `modules/eks/main.tf` — Cluster

```hcl
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [aws_security_group.cluster.id]
  }
}
```

**Private subnets** for control plane ENIs (EKS supports public+private endpoint). `endpoint_private_access = true` allows in-VPC access.

```hcl
  enabled_cluster_log_types = var.enabled_cluster_log_types
```

Ships API and audit logs to CloudWatch when enabled—useful for troubleshooting and compliance.

---

## Managed Node Group

```hcl
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }
}
```

`max_unavailable = 1` allows rolling updates without taking all nodes offline.

---

## `security_groups.tf`

```hcl
resource "aws_security_group" "cluster" {
  description = "EKS cluster control plane security group"
  vpc_id      = var.vpc_id
}
```

Additional SG attached to cluster ENIs alongside the AWS-managed cluster SG.

```hcl
resource "aws_security_group_rule" "cluster_ingress_nodes_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
}
```

Allows nodes to reach the API server on 443.

```hcl
resource "aws_security_group_rule" "node_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}
```

Cluster communicates with kubelets on ephemeral ports.

---

## `aws_auth.tf` — ConfigMap

```hcl
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this.name
}
```

Generates short-lived token for Terraform Kubernetes provider.

```hcl
provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```

Provider block inside the module (Terraform 0.13+ module-scoped providers).

```hcl
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([{
      rolearn  = aws_iam_role.node.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }])
    mapUsers = yamlencode(var.map_users)
  }

  force = true

  depends_on = [aws_eks_node_group.this]
}
```

`force = true` overwrites existing keys—required when adopting existing ConfigMap. `map_users` allows adding cluster admin IAM users.

**Important:** If you manually edited `aws-auth`, Terraform may reconcile on next apply.

---

## kubectl Configuration

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name $(terraform output -raw cluster_name)
```

Uses IAM identity that created the cluster (has `system:masters` via creator permissions) even before `map_users` is populated.

---

## Destroy Order

Terraform destroys node group before cluster. If destroy hangs, scale node group to zero in Console first.
