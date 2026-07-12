# Module 12 Capstone Solution — Complete Explanation

The capstone integrates all prior modules into one promotable pipeline: **Terraform modules → CI → CD → K8s → Monitoring → Rollback**.

---

## Repository Layout

| Path | Role |
| --- | --- |
| `environments/*/terraform.tfvars` | Per-env sizing, CIDR, naming |
| `terraform/modules/networking` | VPC, subnets, NAT, IGW |
| `terraform/modules/eks` | EKS cluster, node group, OIDC |
| `terraform/modules/ecr` | Container registry + lifecycle |
| `app/` | Node.js API with `/health` and `/metrics` |
| `kubernetes/base` | Shared Deployment, Service, ServiceMonitor |
| `kubernetes/overlays/*` | Env-specific replicas, resources, ECR URLs |
| `.github/workflows/` | CI, CD x3, rollback, monitoring |

---

## Terraform Modules

### `modules/networking/main.tf`

- **2 AZ design** — `public` subnets (0,1) for NAT/IGW; `private` subnets (2,3) for EKS nodes.
- **Single NAT gateway** — Cost optimization for training (prod may use NAT per AZ).
- **Kubernetes subnet tags** — `kubernetes.io/role/elb` and `internal-elb` for future LoadBalancer controllers.

### `modules/eks/main.tf`

- **`aws_eks_cluster`** — Private subnet placement; public API endpoint enabled for `kubectl` from CI.
- **`aws_eks_node_group`** — Managed nodes with `desired_size = var.node_count`.
- **OIDC provider** — Created from cluster TLS certificate for IRSA (Fluent Bit, future workloads).

### `modules/ecr/main.tf`

- **Scan on push** — Vulnerability scanning enabled.
- **Lifecycle policy** — Expire images beyond 30 to control storage cost.

### Root `main.tf`

Wires modules in dependency order: `networking` → `ecr` + `eks` (eks needs VPC outputs).

**State isolation:** CD workflows set `key = "<env>/terraform.tfstate"`.

---

## Application (`app/`)

### `src/server.js`

| Route | Behavior |
| --- | --- |
| `GET /health` | JSON `{ status, environment, version }` for probes and smoke tests |
| `GET /metrics` | Prometheus text format (`capstone_uptime_seconds`, `capstone_info`) |
| `GET /` | Plain text banner |

Environment variables `ENVIRONMENT` and `VERSION` are set by Kubernetes deployment / CD workflow.

### `Dockerfile`

- **Multi-stage** — Smaller runtime image.
- **`USER app`** — Non-root security practice.
- **`HEALTHCHECK`** — Docker-level health using `/health`.

### `src/server.test.js`

Node built-in test runner — CI runs `npm test` before build.

---

## Kubernetes (Kustomize)

### Base (`kubernetes/base/`)

- **Namespace** `capstone-app`
- **Deployment** — Rolling update `maxUnavailable: 0` for zero-downtime deploys.
- **Probes** — `readinessProbe` and `livenessProbe` on `/health`.
- **ServiceMonitor** — Label `release: kube-prometheus-stack` for Prometheus Operator.

### Overlays

| Overlay | Replicas | CPU | ECR repo suffix |
| --- | --- | --- | --- |
| dev | 1 | 100m request | `dev-capstone-api` |
| staging | 2 | 200m request | `staging-capstone-api` |
| prod | 3 | 250m request | `prod-capstone-api` |

**`namePrefix`** — `dev-`, `stg-`, `prod-` prefixes avoid name collisions if multiple overlays applied to same cluster (not the case here — separate clusters).

**`kustomize edit set image`** — CD workflows dynamically set `${ECR_URL}:${{ github.sha }}` at deploy time.

---

## GitHub Actions Workflows

### `ci.yml`

1. **`test` job** — Runs on PR and push; `npm test`.
2. **`build-push` job** — OIDC to ECR; tags with `github.sha` and `latest`.
   - `develop` → dev ECR repo
   - `main` → staging ECR repo (prod images promoted via prod CD)

### `cd-dev.yml`

Triggered on **`develop` push**:

1. `terraform apply` with `dev/terraform.tfstate`
2. `aws eks update-kubeconfig`
3. Kustomize deploy + `rollout status`
4. Optional Helm monitoring install

### `cd-staging.yml`

Triggered on **`main` push**:

1. Plan (plan role) → Apply (staging environment approval) → Deploy
2. **`environment: staging`** gates apply/deploy jobs

### `cd-prod.yml`

**Manual only:**

1. Validate `deploy-prod` input + `main` branch
2. Plan → Apply (`environment: prod`, 2 reviewers) → Deploy
3. **Smoke test** — ephemeral `curl` pod hits `/health`

### `rollback.yml`

Inputs: `environment`, `image_tag`, `confirm=rollback`.

- Resolves ECR URL for environment
- `kustomize edit set image` to previous SHA
- `kubectl apply -k` + `rollout status` + health curl

### `deploy-monitoring.yml`

Manual Helm install of kube-prometheus-stack per environment; reapplies Kustomize so ServiceMonitor is registered.

---

## Promotion Flow

```text
feature branch → PR (CI tests) → merge develop → CD Dev
                              → merge main → CI push staging ECR → CD Staging (approval)
                              → manual CD Prod (confirm + 2 approvals)
```

---

## GitHub Secrets Required

| Secret | Used By |
| --- | --- |
| `TF_STATE_BUCKET` | All CD terraform jobs |
| `TF_LOCK_TABLE` | All CD terraform jobs |
| `AWS_PLAN_ROLE_ARN` | Staging/prod plan |
| `AWS_APPLY_ROLE_ARN` | Per-environment apply (use env secrets) |
| `AWS_EKS_DEPLOY_ROLE_ARN` | kubectl/helm jobs |
| `ECR_PUSH_ROLE_ARN` | CI build-push |

---

## Monitoring Integration

- Base manifest includes **ServiceMonitor** scraping `/metrics` on port 3000.
- `monitoring/helm-values.yaml` sets `serviceMonitorSelectorNilUsesHelmValues: false` so capstone monitors are discovered.
- Extend with Module 11 Fluent Bit for CloudWatch logs.

---

## Cost Management

Running **three EKS clusters** is expensive. Recommended practice:

1. Complete capstone with **dev only**
2. Deploy staging/prod for final validation
3. **Destroy** staging/prod when done

---

## Key Production Lessons

1. **Separate state keys** — dev mistakes cannot touch prod state.
2. **OIDC everywhere** — no long-lived AWS keys in GitHub.
3. **Approval gates** — staging (1), prod (2 + manual).
4. **Rollout verification** — `kubectl rollout status` after every deploy/rollback.
5. **Auditable rollback** — redeploy known `image_tag` via workflow, not only `kubectl rollout undo`.

This solution is your template for real-world GitHub Actions + Terraform + EKS platforms.
