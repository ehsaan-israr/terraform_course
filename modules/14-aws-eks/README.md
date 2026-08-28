# Module 14 - AWS EKS with Terraform

This module is the dedicated **Amazon EKS** lesson. Module 06 only sketched
EKS. The GitHub Actions lab under `project-cicd/` shows *delivery* onto a
cluster. Start here so the cluster itself is understandable before CI.

**Prerequisites:** Modules 04–06, then [Module 13 ECS](../13-aws-ecs/) so the
ECS vs EKS choice is concrete.
**Cost:** An EKS control plane is billed per hour even with zero nodes. Prefer
`terraform plan` in class. Destroy the same day if you apply.

## Learning objectives

By the end of this module you will be able to:

- Draw control plane vs data plane (nodes / Fargate / Karpenter).
- Create an EKS cluster in Terraform with the cluster IAM role.
- Explain managed node groups vs Fargate profiles vs Karpenter.
- Use IRSA (IAM Roles for Service Accounts) instead of node instance roles for
  application AWS access.
- Use access entries (or `aws-auth`) so humans and CI can call the API.
- State what Terraform should own vs what belongs in Kubernetes manifests/CI.
- Decide ECS vs EKS without cargo-culting Kubernetes.

## Why EKS gets its own module

EKS is not "ECS with extra YAML." You operate:

```text
Terraform
  |-- VPC (public + private, Kubernetes subnet tags)
  |-- EKS control plane (AWS-managed Kubernetes API)
  |-- Node IAM + cluster IAM
  |-- Optional: managed node group or Fargate profile
  |-- OIDC provider + IRSA roles
  |-- Add-ons (VPC CNI, CoreDNS, kube-proxy, CSI)
  `-- Access entries / cluster auth

Not Terraform (usually)
  |-- Application Deployments, Services, Ingress
  |-- Image build and tag rollout (see project-cicd/)
```

Mixing Helm releases, Deployments, and the cluster into **one state file**
makes every app ship produce a scary plan. Split them.

## 1. What EKS is

**Amazon Elastic Kubernetes Service** runs a Kubernetes **control plane** for
you (API server, etcd, scheduler). You still provide **compute** for pods:

| Data plane | Who manages VMs | Typical use |
| --- | --- | --- |
| Managed node group | AWS replaces nodes in the group; you pick instance types | Default starting point |
| Fargate profile | No nodes; pods run on Fargate | Burst / isolation; some DaemonSets do not run |
| Karpenter | Provisions EC2 on demand from Kubernetes | Platform teams optimizing bin-packing |

```text
kubectl / CI
      |
      v
+------------------+     +-------------------------+
| EKS control plane|     | Worker nodes (optional) |
| Kubernetes API   | --> | kubelet + pods          |
| AWS-managed      |     | your instance types     |
+------------------+     +-------------------------+
      |
      +-- IRSA --> AWS APIs (S3, RDS IAM auth, ...)
```

If you do not need the Kubernetes API, use [ECS](../13-aws-ecs/) instead.

## 2. Cluster resource

Minimum Terraform pieces:

1. Cluster IAM role with `AmazonEKSClusterPolicy`.
2. Subnets in at least two AZs (EKS requirement).
3. `aws_eks_cluster`.

```hcl
resource "aws_iam_role" "cluster" {
  name               = "${var.name}-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.cluster]
}
```

`authentication_mode = API_AND_CONFIG_MAP` lets you use **access entries**
(Terraform-native) while still supporting the older `aws-auth` ConfigMap.

Pin `version`. Accidental minor upgrades of the control plane are high-risk
plans.

## 3. Networking for EKS

Tag subnets so Kubernetes can place load balancers:

| Tag | Where |
| --- | --- |
| `kubernetes.io/cluster/<name> = shared` | Subnets the cluster may use |
| `kubernetes.io/role/elb = 1` | Public subnets (internet-facing LBs) |
| `kubernetes.io/role/internal-elb = 1` | Private subnets (internal LBs) |

Nodes and most pods belong in **private** subnets. They still need egress to
pull images (NAT or VPC endpoints for ECR/S3/ECR DKR).

Pod IPs: the VPC CNI assigns each pod an address from the subnet. Small
`/24`s run out of IPs quickly. Plan prefix delegation or larger CIDRs before
you scale.

The `project-cicd/` VPC module is a **skeleton** (no IGW, no NAT, no routes).
It exists to teach CI wiring, not to boot pods. The `project/` in this module
adds internet gateway and routes so the network is honest.

## 4. Managed node groups

```hcl
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}
```

Node role policies (all three):

- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`

Lab default in `project/`: `enable_node_group = false` so a curious apply does
not also start EC2. A control plane **without** nodes cannot schedule normal
pods.

## 5. IRSA

Do **not** put application S3 permissions on the node instance role. Every pod
on the node could then use them.

IRSA: the cluster has an OIDC issuer. A Kubernetes service account is annotated
with an IAM role. Only pods using that SA can assume the role.

```hcl
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}
```

The IAM trust policy conditions on `system:serviceaccount:<namespace>:<name>`.

This is the EKS analogue of the ECS **task role**.

## 6. Access to the API

Who may call `kubectl`?

**Modern:** `aws_eks_access_entry` + `aws_eks_access_policy_association`
(for example `AmazonEKSClusterAdminPolicy` for break-glass, or a narrower
policy for CI).

**Older:** `aws-auth` ConfigMap mapping IAM roles to Kubernetes groups. Easy to
drift if Terraform and a controller both edit it.

CI deploy roles should be namespace-scoped, not cluster-admin.

## 7. Add-ons

Manage kube-proxy, VPC CNI, CoreDNS (and usually EBS CSI) as
`aws_eks_addon` with pinned versions. Unmanaged add-ons surprise you during
cluster upgrades.

Keep add-on version bumps in a dedicated PR, not bundled with application
changes.

## 8. What Terraform owns vs kubectl

| Terraform | kubectl / Helm / CI |
| --- | --- |
| Cluster, version, logs | Deployments, Services, Ingress |
| VPC, node groups, IRSA roles | Image tag rollouts |
| Add-ons, access entries | App ConfigMaps/Secrets (or External Secrets) |

`project-cicd/` follows that split: Terraform roots under
`infra/terraform/environments/*`, deploy workflows run `kubectl set image`.

## 9. ECS vs EKS (decision)

Use **ECS** when the unit of work is "run this container behind an ALB" and the
team does not already run Kubernetes.

Use **EKS** when you need CRDs/operators, multi-tenancy patterns from the k8s
ecosystem, or a platform team that already standardizes on Kubernetes.

EKS costs more in people time than in the $0.10/hour control plane. Count
on-call and upgrade labor.

## 10. Project (cluster)

`project/` is a teaching cluster:

- VPC with IGW, public and private subnets, Kubernetes tags
- Optional NAT (`enable_nat_gateway`, default false)
- EKS cluster + cluster IAM
- Optional managed node group (`enable_node_group`, default false)
- OIDC provider + example IRSA role
- Access entry for the caller identity

```bash
cd modules/14-aws-eks/project
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan
# terraform apply   # control plane ~$0.10/hour; nodes extra if enabled
terraform destroy
```

## 11. Optional lab: GitHub Actions delivery

`project-cicd/` is the former standalone CI/CD repo: three sample services,
reusable workflows, OIDC, and **directory-per-environment** Terraform.

Treat `project-cicd/` as a **repository root** if you copy it out.

Honesty about that skeleton: its nested `modules/vpc` and `modules/eks` still
omit IGW, NAT, and node groups. They teach **pipeline wiring**. Use `project/`
in this module to learn a cluster you could actually extend.

See `project-cicd/README.md` for environments, secrets, and the
`develop` / `release/*` / `v*.*.*` promotion model.

## 12. Production practices

- Pin cluster version; upgrade in a dedicated change.
- Private nodes; restrict public API endpoint CIDRs in production.
- IRSA for apps; no node-role god permissions.
- Separate state per cluster/environment.
- Add-ons pinned.
- Backup etcd is AWS's job; backup **your** persistent volumes and app data.
- Do not apply EKS from a laptop onto production.

## 13. Common mistakes

1. Applying the control plane and leaving it all weekend.
2. `/24` subnets and then running out of pod IPs.
3. No NAT/endpoints; nodes cannot pull from ECR.
4. Application IAM on the node role.
5. One Terraform state for cluster **and** all Helm releases.
6. Cluster-admin OIDC role for every GitHub environment.
7. Treating the `project-cicd/` skeleton as production-ready.

## 14. Interview Q&A

**What does AWS manage in EKS vs what you manage?**
AWS: control plane availability and the Kubernetes API. You: VPC, nodes or
Fargate, add-ons, IRSA, application workloads, upgrades of *your* pieces.

**IRSA vs node instance role?**
IRSA scopes AWS credentials to a service account. Node roles are shared by
every pod on the instance.

**Terraform vs GitOps for Deployments?**
Terraform is a good cluster factory. Argo CD / Flux / `kubectl` in CI are
better at high-churn application YAML. Pick one owner per object.

**Why might pods stay Pending?**
No nodes, wrong taints, insufficient instance size, subnet IP exhaustion, or
Fargate profile selectors that do not match.

## Mini project

Do the exercises. Then either:

- Enable the managed node group in `project/` and list every extra billable
  resource in the plan, **or**
- Add a fourth service in `project-cicd/` by reusing workflows (not copy-paste).

## Further reading

- EKS user guide: https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
- IRSA: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
- Access entries: https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html
- Terraform `aws_eks_cluster`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
- Module 13 ECS: [../13-aws-ecs/](../13-aws-ecs/)
