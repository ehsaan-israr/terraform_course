# Module 14 project — EKS cluster (teaching stack)

Hands-on lab for [Module 14](../README.md) **cluster fundamentals**. For GitHub
Actions delivery, use [`../project-cicd/`](../project-cicd/).

**Learning goals:** VPC tags Kubernetes needs, cluster IAM vs node IAM, IRSA
OIDC, and why a control plane with `enable_node_group = false` cannot run pods.

---

## Architecture

```text
Public subnets          Private subnets
  ALB / NAT (optional)    Node group (optional)
  IGW                     Pod IPs (VPC CNI)
           \
            --> EKS control plane (AWS-managed API)
                    |
                    +-- OIDC --> IRSA role for apps/api
```

---

## File index

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.5.0`; AWS + TLS providers. |
| `variables.tf` | CIDRs, cluster version, NAT and node-group flags. |
| `vpc.tf` | VPC, IGW, public/private subnets, Kubernetes tags, optional NAT. |
| `eks.tf` | Cluster IAM role, `aws_eks_cluster`, control-plane log group. |
| `node_group.tf` | Optional managed node group + worker IAM. |
| `irsa.tf` | OIDC provider and example `apps/api` IRSA role. |
| `outputs.tf` | Cluster name, endpoint, OIDC ARN, IRSA role. |

---

## Run

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan
# terraform apply     # ~$0.10/hour control plane even with no nodes
terraform destroy
```

Leave `enable_node_group = false` unless you will add NAT (or VPC endpoints)
and destroy the same day. Private nodes cannot pull images without egress.

---

## After apply (optional)

```bash
aws eks update-kubeconfig --name <cluster_name> --region us-east-1
kubectl get nodes
```

With the default flags you should see the API, and **no Ready nodes**.

Annotate a ServiceAccount to use IRSA:

```yaml
metadata:
  namespace: apps
  name: api
  annotations:
    eks.amazonaws.com/role-arn: <app_irsa_role_arn>
```

---

## Cost warning

EKS control plane, optional NAT, optional `t3.medium` nodes, and CloudWatch
logs are billable. Use a sandbox. Destroy when finished.

The **CI/CD skeleton** in `project-cicd/` is even less complete (no IGW/NAT/
nodes). Do not apply that nested EKS module expecting running pods.
