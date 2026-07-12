# Module 08 Exercise — CD Pipeline with Rolling Updates and Rollback

## Objective

Create a GitHub Actions **CD workflow** that deploys the `course-api` image from ECR to EKS in `us-east-1`, uses a Deployment with explicit **rolling update** settings, and provides **rollback** capability via workflow or documented procedure.

---

## Requirements

1. **Kubernetes manifests** (`k8s/`):
   - `namespace.yaml` — `course-app`
   - `deployment.yaml` — 2 replicas, `RollingUpdate` with `maxSurge: 1`, `maxUnavailable: 0`
   - Liveness/readiness HTTP probes on `/health` (port 3000)
   - Image placeholder or Kustomize pattern for ECR URI
   - `service.yaml` — ClusterIP (port 80 → target 3000)
   - `configmap.yaml` — optional app configuration

2. **`.github/workflows/cd.yml`**:
   - Trigger: `workflow_dispatch` with `image_tag` input; `push` to `main` optional
   - OIDC authentication to AWS (`role-to-assume`)
   - `aws eks update-kubeconfig` for cluster in `us-east-1`
   - Deploy using `kubectl apply` or `kubectl set image`
   - Wait for rollout: `kubectl rollout status` with timeout
   - Fail job if rollout fails

3. **Rollback** (choose one or both):
   - `.github/workflows/rollback.yml` — manual workflow running `kubectl rollout undo`
   - Document CLI rollback steps in `ROLLBACK.md`

4. **Integration with Module 07**:
   - CD deploys image `${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/course-api:${SHA}`

---

## Constraints

- Region: **`us-east-1`**
- No kubeconfig or AWS keys committed to Git
- `revisionHistoryLimit` ≥ 3 on Deployment
- CD must not run on every PR by default (protect production namespace)
- Use pinned GitHub Action versions

---

## Tasks

### Task 1 — Kubernetes manifests

- [ ] Create Deployment with rolling update strategy documented in comments
- [ ] Configure probes matching `/health` on port 3000
- [ ] Create Service mapping port 80 → 3000
- [ ] Manually deploy once and verify 2 replicas healthy

### Task 2 — CD workflow

- [ ] Create `cd.yml` with OIDC + EKS kubeconfig
- [ ] Substitute image tag from `github.sha` or workflow input
- [ ] Apply manifests and wait for rollout success
- [ ] Verify new Pods run the expected image (`kubectl describe pod`)

### Task 3 — Rolling update observation

- [ ] Deploy `v1` (or SHA-1), then deploy `v2` (or SHA-2)
- [ ] Watch `kubectl get pods -w` during update
- [ ] Confirm zero-downtime behavior with `maxUnavailable: 0`

### Task 4 — Rollback

- [ ] Create `rollback.yml` or `ROLLBACK.md` with undo steps
- [ ] Simulate bad deploy (broken image tag) and roll back
- [ ] Verify `kubectl rollout history` shows revisions

---

## Expected Deliverables

| Deliverable | Path |
| --- | --- |
| K8s manifests | `k8s/*.yaml` |
| CD workflow | `.github/workflows/cd.yml` |
| Rollback workflow or docs | `rollback.yml` or `ROLLBACK.md` |
| Deploy notes | Image URI and cluster name documented |

---

## Validation Checklist

- [ ] Deployment specifies `maxSurge: 1` and `maxUnavailable: 0`
- [ ] CD workflow uses OIDC (not static AWS keys)
- [ ] `kubectl rollout status` succeeds after CD run
- [ ] Service endpoints match ready Pods only
- [ ] `/health` returns 200 via port-forward after CD
- [ ] Rollback restores previous working revision
- [ ] `revisionHistoryLimit` allows multiple undo targets
- [ ] CD does not deploy to EKS on unreviewed PRs by default
- [ ] Image tag in cluster matches ECR tag from Module 07 CI
- [ ] All resources in `course-app` namespace

**Do not read `solution/` until all items are checked.**
