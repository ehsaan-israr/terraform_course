# Module 05 Exercise — Deploy Sample Application to EKS

## Objective

Build and deploy a containerized sample web application to your EKS cluster in `us-east-1` using Kubernetes manifests and `kubectl`. The application must expose a `/health` endpoint and run in a dedicated namespace.

---

## Requirements

1. Create a **Dockerfile** based on nginx (or a minimal web server) that serves:
   - A default page at `/`
   - A JSON health response at `/health` returning HTTP 200
2. Write Kubernetes manifests for:
   - `namespace.yaml` — namespace `course-app` (or your chosen name, used consistently)
   - `configmap.yaml` — at least `APP_ENV` and `APP_MESSAGE`
   - `deployment.yaml` — **2 replicas**, resource requests/limits, liveness and readiness probes on `/health`
   - `service.yaml` — ClusterIP on port 80
   - `ingress.yaml` — optional; document prerequisites if included
3. Push the image to **Amazon ECR** in `us-east-1` and reference the full ECR image URI in the Deployment.
4. Apply all manifests and verify the rollout succeeds.
5. Access the app via `kubectl port-forward` and confirm `/` and `/health` respond correctly.

---

## Constraints

- Use region **`us-east-1`** for ECR and EKS.
- Do **not** commit AWS credentials or kubeconfig secrets to Git.
- Use labels consistently: `app`, `version`, `component` (minimum: `app`).
- Deployment must use `RollingUpdate` strategy (default is acceptable).
- Probes must use `httpGet` on port 80 (or your container port).
- Resource requests: at least `cpu: 50m`, `memory: 64Mi`.

---

## Tasks

### Task 1 — Container image

- [ ] Write `Dockerfile` with custom `/health` endpoint
- [ ] Build image locally and test with `docker run -p 8080:80 <image>`
- [ ] Create ECR repository `course-nginx` (or your name)
- [ ] Push tagged image `v1` to ECR

### Task 2 — Kubernetes manifests

- [ ] Create `k8s/namespace.yaml`
- [ ] Create `k8s/configmap.yaml` and wire env vars into the Deployment
- [ ] Create `k8s/deployment.yaml` with 2 replicas, probes, and resource limits
- [ ] Create `k8s/service.yaml` targeting your Pod labels
- [ ] (Optional) Create `k8s/ingress.yaml` with ALB annotations

### Task 3 — Deploy and verify

- [ ] Run `aws eks update-kubeconfig` for your cluster
- [ ] `kubectl apply -f k8s/` in correct order
- [ ] `kubectl rollout status` shows success
- [ ] Port-forward and curl `/health` returns JSON with status 200

### Task 4 — Operations practice

- [ ] Scale Deployment to 3 replicas; observe new Pods
- [ ] `kubectl logs` and `kubectl describe` a Pod
- [ ] Delete one Pod and watch the Deployment recreate it

---

## Expected Deliverables

| Deliverable | Location |
| --- | --- |
| Dockerfile | `Dockerfile` or `docker/Dockerfile` |
| Kubernetes manifests | `k8s/*.yaml` |
| Brief deploy notes | `DEPLOY.md` (commands you used, ECR URI placeholder) |
| No secrets in Git | `.gitignore` includes `.env`, kubeconfig backups |

---

## Validation Checklist

Use this checklist to confirm your work before comparing with the solution:

- [ ] `kubectl get nodes` shows all nodes `Ready`
- [ ] Namespace exists: `kubectl get ns course-app`
- [ ] Two Pods `Running` with `READY 1/1`
- [ ] `kubectl describe deployment` shows successful rollout
- [ ] Liveness and readiness probes configured on `/health`
- [ ] ConfigMap keys visible in Pod env or mounted files
- [ ] Service has endpoints: `kubectl get endpoints -n course-app`
- [ ] `curl http://localhost:8080/health` returns `{"status":"healthy"...}` (via port-forward)
- [ ] Image URI points to ECR in `us-east-1`, not `latest` without registry
- [ ] All resources use the same namespace (not scattered in `default`)

**Do not read `solution/` until you have checked every item above.**
