output "vpc_id" {
  description = "Lab VPC ID."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs tagged for internal load balancers and nodes."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_ids" {
  description = "Public subnet IDs tagged for internet-facing load balancers."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "Pinned Kubernetes version."
  value       = aws_eks_cluster.this.version
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider used for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "app_irsa_role_arn" {
  description = "Example IRSA role for serviceaccount apps/api. Annotate the ServiceAccount with this ARN."
  value       = aws_iam_role.app_irsa.arn
}

output "node_group_enabled" {
  description = "Whether a managed node group is included in this configuration."
  value       = var.enable_node_group
}

output "cost_warning" {
  description = "Billing reminder before apply."
  value       = "EKS control plane is billed hourly with zero nodes. NAT and node groups add more. Destroy the same day."
}
