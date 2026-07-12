# Module 12 Capstone Exercise: Full Production Pipeline

## Objective

Design and implement a **production-ready** GitHub Actions pipeline that provisions AWS infrastructure with Terraform (VPC, EKS, ECR), builds and deploys a containerized application to Kubernetes across **dev**, **staging**, and **prod**, with approval gates, rollback capability, and integrated monitoring.

## Requirements

### Infrastructure (Terraform)

1. **Modules**
   - `networking` — VPC, public/private subnets across 2 AZs, NAT gateway, IGW.
   - `eks` — EKS cluster 1.28+, managed node group, OIDC provider for IRSA.
   - `ecr` — ECR repository with scan-on-push.

2. **Environments**
   - `environments/dev/terraform.tfvars`
   - `environments/staging/terraform.tfvars`
   - `environments/prod/terraform.tfvars`
   - Separate state key per environment in shared S3 backend.

3. **Variables per environment**
   - `node_count`, `instance_types`, `cluster_version` (staging/prod ≥ dev).

### Application

1. Simple HTTP API (Node.js, Python, or Go) with:
   - `GET /health` → JSON with status, environment, version (Git SHA).
   - `GET /metrics` → Prometheus format (optional bonus).

2. `Dockerfile` — multi-stage build, non-root user, health check.

### Kubernetes

1. **Kustomize** base: Deployment, Service, ServiceMonitor.
2. **Overlays** per environment: replicas, resource limits, image reference, namespace.
3. Rolling update strategy with `maxUnavailable: 0`.

### GitHub Actions Workflows

1. **`ci.yml`** — On PR and push: lint/test, build image, push to ECR (dev repo on PR; env-specific on branch).
2. **`cd-dev.yml`** — Push to `develop`: Terraform apply dev, deploy Kustomize overlay, rollout status.
3. **`cd-staging.yml`** — Push to `main`: plan, **approval**, apply staging, deploy.
4. **`cd-prod.yml`** — Manual only: confirmation input, **2 approvals**, apply prod, deploy.
5. **`rollback.yml`** — Manual: inputs `environment`, `image_tag`; redeploy overlay with tag.
6. **`deploy-monitoring.yml`** — Install Module 11 stack post-deploy (or call reusable workflow).

### Security & Production

- OIDC only — no static AWS keys.
- Reuse or extend Module 10 reusable workflows where possible.
- Document branch protection and environment setup.
- Region: `us-east-1`.

## Constraints

- Do not combine dev/staging/prod into a single Terraform state.
- Production deploy must not run automatically on push.
- Rollback must verify rollout success before completing.
- Pin all action and provider versions.
- EKS clusters must deploy into private subnets with NAT egress.

## Tasks

### Task 1: Terraform Modules

Implement networking, eks, and ecr modules; wire in root `main.tf`.

### Task 2: Environment Tfvars

Create three tfvars files with distinct sizing and naming.

### Task 3: Application & Docker

Build containerized API with tests (at least one unit test).

### Task 4: Kustomize Manifests

Base + three overlays; image tag must be overridable by CD workflow.

### Task 5: CI Workflow

Test, build, push to ECR with OIDC; cache Docker layers if possible.

### Task 6: CD Workflows

Implement dev/staging/prod with correct triggers and GitHub Environments.

### Task 7: Rollback Workflow

Accept `image_tag` input; patch deployment; wait for rollout.

### Task 8: Monitoring Integration

Deploy ServiceMonitor; document Grafana dashboard access.

### Task 9: Documentation

Root README section: architecture, secrets table, promotion flow dev → staging → prod.

## Expected Deliverables

| Deliverable | Path |
| --- | --- |
| Terraform modules | `terraform/modules/{networking,eks,ecr}/` |
| Environment configs | `environments/*/terraform.tfvars` |
| Application | `app/` |
| Kubernetes | `kubernetes/base/`, `kubernetes/overlays/*/` |
| Workflows | `.github/workflows/*.yml` |
| Monitoring | `monitoring/` |
| Architecture doc | README or `docs/architecture.md` |

## Validation Checklist

- [ ] `terraform plan` succeeds for all three environments.
- [ ] CI runs on pull request and passes tests.
- [ ] Dev CD deploys app accessible via port-forward `/health`.
- [ ] Staging CD requires one approval before apply/deploy.
- [ ] Prod CD requires manual trigger, confirmation, and two approvals.
- [ ] ECR images tagged with `github.sha`.
- [ ] Kustomize overlays change replica count between dev and prod.
- [ ] Rollback workflow successfully deploys a previous image tag.
- [ ] `kubectl rollout status` passes after every deploy and rollback.
- [ ] ServiceMonitor appears in Prometheus targets as UP.
- [ ] No AWS access keys in repository.
- [ ] Terraform modules use outputs correctly between networking → eks.
- [ ] Private subnets used for EKS nodes.
