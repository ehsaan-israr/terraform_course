# Module 08 Solution — Line-by-Line Explanation

---

## k8s/deployment.yaml

### Rolling update strategy

```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

With 2 replicas: Kubernetes may create a 3rd Pod (`maxSurge: 1`) before terminating an old one, but never leaves fewer than 2 ready Pods (`maxUnavailable: 0`) — **zero-downtime** rollout.

```yaml
  revisionHistoryLimit: 10
```

Keeps 10 old ReplicaSets for `kubectl rollout undo` and the rollback workflow.

### Image placeholder

```yaml
          image: IMAGE_PLACEHOLDER
```

The CD workflow substitutes the real ECR URI via `sed` before `kubectl apply`. Alternative: `kubectl set image deployment/course-api course-api=$IMAGE`.

### Probes

```yaml
          readinessProbe:
            httpGet:
              path: /health
              port: http
```

Readiness gates Service endpoints — during rollout, only healthy new Pods receive traffic.

```yaml
          livenessProbe:
            initialDelaySeconds: 15
```

Allows Node.js startup time before liveness failures trigger restarts.

### Environment

```yaml
            - name: PORT
              value: "3000"
```

Matches the Express app default from Module 07.

---

## k8s/service.yaml

```yaml
      port: 80
      targetPort: http
```

Exposes HTTP on port 80 inside the cluster while the container listens on 3000 — common pattern for in-cluster consumers.

---

## .github/workflows/cd.yml

### Triggers

```yaml
  workflow_dispatch:
    inputs:
      image_tag:
```

Manual deploy of any ECR tag (e.g., re-deploy a known-good SHA).

```yaml
  push:
    paths:
      - "module-08-cd/**"
```

Auto-deploy only when CD-related files change — avoids deploying on unrelated commits.

### Environment protection

```yaml
    environment: production
```

Optional GitHub Environment with required reviewers (configure in Settings → Environments).

### OIDC and kubeconfig

```yaml
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
```

Same OIDC pattern as Module 07; CD role also needs EKS access.

```yaml
      - run: aws eks update-kubeconfig --name "${CLUSTER_NAME}"
```

Generates kubeconfig on the runner using temporary IAM credentials.

### Deploy steps

```yaml
          sed "s|IMAGE_PLACEHOLDER|${IMAGE}|g" ... | kubectl apply -f -
```

Renders manifest with immutable ECR tag (`GITHUB_SHA` or manual input).

```yaml
          kubectl rollout status deployment/${DEPLOYMENT_NAME} --timeout=300s
```

**Fails the workflow** if new Pods don't become ready — prevents silent broken deploys.

### Smoke test

```yaml
          kubectl run curl-smoke ... curl -sf "http://course-api.course-app.svc.cluster.local/health"
```

In-cluster HTTP check against the ClusterIP DNS name.

---

## .github/workflows/rollback.yml

```yaml
      - run: kubectl rollout history deployment/${DEPLOYMENT_NAME}
```

Lists revisions before undo — operators pick revision in workflow input.

```yaml
          kubectl rollout undo ... --to-revision="${REVISION}"
```

Rolls to a specific revision; omitting input rolls to **previous** revision.

---

## CLI Rollback (manual)

```bash
kubectl rollout history deployment/course-api -n course-app
kubectl rollout undo deployment/course-api -n course-app
kubectl rollout status deployment/course-api -n course-app
```

---

## IAM Note

Extend the Module 07 role or create `github-actions-eks-deploy-role` with:

- `eks:DescribeCluster`
- EKS **access entry** mapping the role to `AmazonEKSClusterAdminPolicy` (learning) or a custom RBAC RoleBinding (production)

GitHub variables:

| Variable | Example |
| --- | --- |
| `EKS_CLUSTER_NAME` | `course-eks` |
| `AWS_REGION` | `us-east-1` |
