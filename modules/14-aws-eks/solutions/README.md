# Module 14 Solutions — AWS EKS

These answers correspond to `../exercises/README.md`.

## Part A — cluster fundamentals

### A1: Control plane vs data plane

- Control plane: `aws_eks_cluster.this` (plus its IAM role).
- With `enable_node_group = false` there is no managed node group (and no
  Fargate profile). No worker capacity.
- A normal Deployment stays `Pending` (no nodes). Fargate would still need a
  profile you have not created.

### A2: Subnet tags

Public:

- `kubernetes.io/role/elb = 1` — internet-facing load balancers
- `kubernetes.io/cluster/<name> = shared` — cluster may use the subnet

Private:

- `kubernetes.io/role/internal-elb = 1` — internal load balancers
- same cluster shared tag

### A3: IRSA vs node role

1. `irsa.tf` — `aws_iam_openid_connect_provider.eks`
2. `system:serviceaccount:apps:api`
3. Every pod on the node can use the instance role. IRSA limits AWS access to
   one service account.

### A4: Compare to the CI/CD skeleton

`project/` adds, among others:

1. Internet gateway and public default route
2. Route tables / associations (and optional NAT)
3. Kubernetes ELB/internal-elb and cluster tags
4. Optional managed node group + worker IAM
5. OIDC provider and IRSA example role
6. Control-plane log group with retention

The CI/CD modules still omit IGW, NAT, routes, and nodes. They teach pipeline
layout, not a bootable cluster.

## Part B — GitHub Actions delivery

### B1: Trace a Flask change

`ci.yml` path filter sets `flask-api: true` and the other service/terraform
flags false.

Runs: `changes`, then `flask-api` (reusable Python lint + pytest).

Skipped: `fastapi-api`, `go-api`, and all `terraform-plan-*` jobs.

On `develop`, `deploy-dev.yml` would build/push/deploy. With a Flask-only
change, a well-written release workflow should still **prefer** deploying only
changed services; read `reusable-release.yml` / `deploy-dev.yml` toggles. The
default teaching pipelines deploy the catalog unless inputs disable a service.

### B2: Map Git refs to environments

| Git ref | GitHub Environment | Typical action |
| --- | --- | --- |
| PR into `main` | (none for apps); Terraform jobs use `dev`/`qa`/`prod`/`iaas` | Lint/test + Terraform **plan** |
| Push to `develop` | `dev` | Build, ECR push, EKS deploy |
| Push to `release/1.4` | `qa` | Build, ECR push, EKS deploy |
| Tag `v1.2.3` | `prod` | Build, ECR push, EKS deploy with approval |
| Push to `main` changing iaas Terraform | `iaas` | Terraform **apply** via `terraform-iaas.yml` |

### B3: Terraform state boundaries

| Root | Backend key | Sample CIDR |
| --- | --- | --- |
| dev | `dev/terraform.tfstate` | `10.0.0.0/16` |
| prod | `prod/terraform.tfstate` | `10.2.0.0/16` |

One state file would couple prod cluster replacement to a dev experiment.
Locking, IAM, and approvals would also mix.

`REPLACE_ME-tfstate` is a placeholder. Real bucket names stay in sandbox
overrides or a private fork — not in the public course.

### B4: Who owns what?

Terraform: cluster, VPC/nodes, IAM/IRSA, add-ons. Deploy workflow: image
build, pushing to ECR, and rolling the Deployment to a new tag.

## Interview drill

1. Same idea: per-workload AWS credentials. ECS uses a task role. EKS uses
   IRSA on a service account. Do not put app permissions on the node/instance
   role (EKS) or the execution role (ECS).
2. So the prod role cannot be assumed from a `develop` workflow run. Stolen
   workflow YAML still cannot use the prod role without matching
   `environment:prod`.
3. Choose ECS when you want containers without operating Kubernetes. Choose
   EKS when Kubernetes APIs and ecosystem are requirements you can staff.
