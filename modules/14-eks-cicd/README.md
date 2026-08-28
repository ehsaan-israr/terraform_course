# Module 14 - GitHub Actions CI/CD for EKS and Terraform

This module is a **monorepo delivery lab**: three small services, reusable GitHub
Actions, OIDC into AWS, Terraform roots per environment, and EKS rollouts.

Module 11 compared GitOps products. This module implements one concrete pattern:
GitHub Actions + reusable workflows + environment-scoped IAM roles.

## Learning objectives

By the end of this module you will be able to:

- Structure a monorepo so path filters run only the pipelines that changed.
- Split CI (lint/test/plan) from CD (build/push/deploy) across branches and tags.
- Authenticate GitHub Actions to AWS with OIDC instead of static access keys.
- Keep Terraform in `infra/terraform/environments/<env>` with remote state.
- Explain why reusable workflows beat copy-pasted deploy YAML per service.
- Map `develop` / `release/*` / `v*.*.*` to dev / qa / prod without hardcoding
  account IDs in the workflow file.
- Name EKS cost and blast-radius risks before applying.

## What the project contains

```text
project/                          # treat as repo root when using Actions
  services/
    flask-api/                    # Python
    fastapi-api/                  # Python
    go-api/                       # Go
  infra/terraform/
    modules/{vpc,eks}/            # shared modules
    environments/{dev,qa,prod,iaas}/
  .github/
    services.yaml                 # service catalog for humans
    actions/                      # composite actions (OIDC, Docker, kubectl, tf)
    workflows/                    # CI, deploys, reusable-*.yml
```

Sample apps only expose `/health`. They exist so CI and Docker pipelines have
something real to lint, test, and build.

## Delivery architecture

```text
Pull request
  |-- path filter
  |     |-- services/flask-api  -> reusable-python-ci
  |     |-- services/go-api     -> reusable-go-ci
  |     `-- infra/terraform     -> terraform plan (dev, qa, prod, iaas)
  |
develop branch  ----------------> deploy-dev  (ECR + kubectl)
release/*       ----------------> deploy-qa
v1.2.3 tag      ----------------> deploy-prod (environment approval)
main + iaas paths --------------> terraform-iaas apply
```

GitHub Environments inject `AWS_ROLE_ARN_*`, `ECR_REGISTRY`, and
`EKS_CLUSTER_NAME`. The workflow YAML stays generic.

## Terraform layout

Directory-per-environment matches Module 7. Each root has its own backend key:

| Root | State key | CIDR in the sample |
| --- | --- | --- |
| `environments/dev` | `dev/terraform.tfstate` | `10.0.0.0/16` |
| `environments/qa` | `qa/terraform.tfstate` | `10.1.0.0/16` |
| `environments/prod` | `prod/terraform.tfstate` | `10.2.0.0/16` |
| `environments/iaas` | `iaas/terraform.tfstate` | `10.10.0.0/16` |

Backend bucket names are `REPLACE_ME-tfstate`. That is intentional. Put real
bucket names in a sandbox copy of `backend.tf`; never commit a company bucket.

### Honesty about the EKS skeleton

The VPC and EKS modules teach **module composition and CI wiring**. They are
not a production cluster:

- No internet gateway, NAT, or route tables.
- No node group or Fargate profile.
- Control plane only.

`terraform validate` should succeed. `terraform apply` would create a billed
control plane that cannot run pods. Extend the modules before using this as a
real platform, or keep applies off and use plan-only labs.

## OIDC, not access keys

`configure-aws` assumes `AWS_ROLE_ARN` from the GitHub Environment. Trust is
bound to `repo:ORG/REPO:environment:dev` (and qa/prod/iaas). That is the same
pattern as Module 13 Glue CI, applied to EKS and Terraform.

## Local loop

From `modules/14-eks-cicd/project`:

```bash
# App CI without AWS
cd services/flask-api && pip install -r requirements-dev.txt && pytest
cd services/fastapi-api && pip install -r requirements-dev.txt && pytest
cd services/go-api && go test ./...

# Terraform without applying
cd infra/terraform/environments/dev
terraform init -backend=false
terraform fmt -recursive
terraform validate
```

Copy this `project/` directory into its own repository to run the GitHub
Actions as written.

## Production practices

- **Path filters** so a Go change does not rebuild Python images.
- **Reusable workflows** for the repeated lint/test/plan/apply shape.
- **Environment protection** on `prod` and `iaas` (reviewers, wait timer).
- **Remote state + lock table** per environment, not one state for all clusters.
- **Image tags from git SHA or release tag**, not `:latest` in production.
- **Least privilege** deploy roles: ECR push, `eks:DescribeCluster`, and
  namespace-scoped Kubernetes access — not `AdministratorAccess`.

## Common mistakes

1. Static `AWS_ACCESS_KEY_ID` in GitHub secrets.
2. One Terraform state for dev, qa, and prod clusters.
3. Applying EKS from a laptop.
4. Forgetting NAT/nodes, then wondering why pods stay `Pending`.
5. Deploying `:latest` so you cannot roll back.
6. Leaving an EKS control plane running after class.

## Interview Q&A

**Why reusable workflows instead of one giant `ci.yml`?**
Callers stay short. Python, Go, Terraform, and EKS can evolve independently.
Inputs and secrets stay explicit.

**How do you deploy three services without three copies of Docker/EKS YAML?**
`reusable-release.yml` loops the service catalog. Composite actions hide ECR
login and `kubectl set image`.

**What should Terraform own vs kubectl?**
Terraform owns cluster, VPC, node groups, IRSA, and add-ons. CI owns image
build and rolling the Deployment to a new tag. Mixing app releases into the
cluster state file creates noisy plans.

**Why a separate `iaas` environment?**
Shared foundation (state bucket, OIDC provider, maybe a hub VPC) has a
different blast radius and approval bar than an app cluster.

## Mini project

Add a fourth service `node-api` **or** extend the EKS module with a managed node
group. You should reuse `reusable-python-ci` / `reusable-docker-build` /
`reusable-eks-deploy` rather than pasting a new workflow from scratch.

## Further reading

- EKS: https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
- Terraform `aws_eks_cluster`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
- GitHub OIDC with AWS: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
- Reusable workflows: https://docs.github.com/en/actions/using-workflows/reusing-workflows
