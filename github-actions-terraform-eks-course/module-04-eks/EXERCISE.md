# Module 04 Exercise: Amazon EKS with Terraform

## Objective

Build a Terraform configuration that provisions an Amazon EKS cluster with a managed node group, IAM roles, security groups, and `aws-auth` ConfigMap management—composed on top of a VPC networking module.

---

## Requirements

1. Terraform >= 1.5, AWS provider `~> 5.0`, Kubernetes provider `~> 2.23`.
2. Reuse or recreate the VPC module from Module 03 (2 AZs, public/private subnets, NAT, IGW).
3. EKS cluster with configurable Kubernetes version.
4. Managed node group in **private subnets** only.
5. IAM cluster role and node role with required AWS managed policies.
6. Security groups for cluster and node communication.
7. `aws-auth` ConfigMap managed via Terraform (Kubernetes provider).
8. Root-level `versions.tf`, `variables.tf`, `outputs.tf`, `main.tf`.
9. `terraform.tfvars.example` and `.gitignore`.
10. All resources tagged with `Environment`, `Project`, `ManagedBy`.

---

## Constraints

- Minimum instance type: `t3.medium` (EKS system pods need adequate resources).
- Node group: 1–3 nodes for learning (configurable).
- Do not expose the Kubernetes API publicly unless you document the security trade-off (`endpoint_public_access` default false recommended).
- Do not hard-code AWS account IDs.
- Cluster name must be unique within the region/account.

---

## Tasks

### Task 1: EKS Module Scaffold

Create `modules/eks/` with:

```text
modules/eks/
├── versions.tf
├── variables.tf
├── main.tf
├── iam.tf
├── security_groups.tf
├── aws_auth.tf
└── outputs.tf
```

### Task 2: IAM Roles

1. **Cluster role** trusted by `eks.amazonaws.com`.
2. Attach `AmazonEKSClusterPolicy`.
3. **Node role** trusted by `ec2.amazonaws.com`.
4. Attach worker, CNI, and ECR read-only policies.

### Task 3: EKS Cluster

1. Create `aws_eks_cluster` using private subnets.
2. Configure cluster VPC config with security group(s).
3. Enable control plane logging (api, audit) — optional but recommended.
4. Set `endpoint_private_access = true`.

### Task 4: Managed Node Group

1. Create `aws_eks_node_group` in private subnets.
2. Use the node IAM role.
3. Configure scaling: min 1, max 3, desired 2 (defaults OK).
4. Add update config with `max_unavailable = 1`.

### Task 5: Security Groups

1. Node security group allowing cluster ↔ node traffic.
2. Document rules: 443 from cluster to nodes, kubelet ports, node-to-node.

### Task 6: aws-auth ConfigMap

Using the Kubernetes provider:

1. Map the node IAM role to `system:bootstrappers` and `system:nodes` groups.
2. Optionally map your IAM user/role for cluster admin (document in comments).
3. Use `depends_on` so cluster is ACTIVE before apply.

### Task 7: Root Composition

Wire modules together:

```hcl
module "vpc" { ... }
module "eks" {
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ...
}
```

### Task 8: Outputs

Export at minimum:

| Output | Purpose |
| --- | --- |
| `cluster_name` | kubectl configuration |
| `cluster_endpoint` | API server URL |
| `cluster_arn` | CI/CD references |
| `configure_kubectl` | Helper command string |
| `node_group_arn` | Operations / debugging |

### Task 9: Apply and Validate

```bash
terraform init
terraform apply
aws eks update-kubeconfig --name <cluster>
kubectl get nodes
```

---

## Expected Deliverables

| Deliverable | Description |
| --- | --- |
| `modules/eks/` | Complete EKS module |
| `modules/vpc/` | VPC module (from Module 03 or equivalent) |
| Root Terraform | Composed configuration |
| Running EKS cluster | Nodes in Ready state |
| kubectl access | Successful `kubectl get nodes` |

---

## Validation Checklist

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` succeeds
- [ ] EKS cluster status is ACTIVE
- [ ] Node group status is ACTIVE
- [ ] Nodes run in private subnets (verify via EC2 Console)
- [ ] `kubectl get nodes` shows all nodes Ready
- [ ] `kubectl get configmap aws-auth -n kube-system` shows node role mapping
- [ ] Cluster and node IAM roles have correct trust policies
- [ ] Security groups allow required cluster-node traffic
- [ ] Tags `Environment`, `Project`, `ManagedBy` on cluster and nodes
- [ ] `configure_kubectl` output works
- [ ] No public K8s API exposure (unless intentionally enabled and documented)
- [ ] `terraform destroy` removes cluster and node group cleanly

---

**When finished:** Compare with `solution/` and read `SOLUTION.md`.
