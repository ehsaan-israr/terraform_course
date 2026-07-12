# Module 05 Solution — Line-by-Line Explanation

This document explains every important line in the solution. Replace `111122223333` with your AWS account ID before deploying.

---

## Dockerfile

```dockerfile
FROM nginx:1.27-alpine
```

Uses the official lightweight nginx image on Alpine Linux — small attack surface and fast pulls.

```dockerfile
RUN apk add --no-cache curl \
    && mkdir -p /usr/share/nginx/html/health
```

`curl` supports the Docker `HEALTHCHECK` instruction. The directory holds the static JSON health response.

```dockerfile
COPY html/index.html /usr/share/nginx/html/index.html
COPY html/health/index.json /usr/share/nginx/html/health/index.json
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
```

Copies static content and custom nginx server block. Separating config from the image base keeps changes declarative.

```dockerfile
EXPOSE 80
```

Documents the container port (informational; Kubernetes `containerPort` is authoritative).

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1
```

Docker-level health check for local `docker run` testing. Kubernetes uses its own probes in `deployment.yaml`.

---

## nginx/default.conf

```nginx
location /health {
    default_type application/json;
    alias /usr/share/nginx/html/health/index.json;
    access_log off;
}
```

Serves static JSON at `/health` without access logging (reduces noise from kube probes). `default_type` sets `Content-Type: application/json`.

---

## k8s/namespace.yaml

```yaml
metadata:
  name: course-app
```

Isolates course resources from `default` and other workloads — simplifies RBAC and cleanup (`kubectl delete namespace course-app`).

---

## k8s/configmap.yaml

```yaml
data:
  APP_ENV: "learning"
  APP_MESSAGE: "Hello from EKS Module 05"
```

Non-sensitive configuration. The Deployment uses `envFrom.configMapRef` to inject these as environment variables (visible via `kubectl exec ... env`).

---

## k8s/deployment.yaml

```yaml
spec:
  replicas: 2
```

Runs two Pods for basic high availability across nodes (if the node group has ≥2 nodes).

```yaml
  revisionHistoryLimit: 5
```

Keeps five ReplicaSets for rollback history (used heavily in Module 08).

```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

During updates, allow one extra Pod (`maxSurge: 1`) but never drop below desired capacity (`maxUnavailable: 0`) — zero-downtime rolling updates.

```yaml
          image: 111122223333.dkr.ecr.us-east-1.amazonaws.com/course-nginx:v1
          imagePullPolicy: Always
```

Full ECR URI required on EKS. `Always` ensures nodes pull the tag even if cached (prefer immutable SHA tags in production).

```yaml
          envFrom:
            - configMapRef:
                name: course-nginx-config
```

Injects all ConfigMap keys as environment variables into the container.

```yaml
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 250m
              memory: 128Mi
```

**Requests** help the scheduler place Pods; **limits** cap usage and prevent noisy-neighbor issues.

```yaml
          livenessProbe:
            httpGet:
              path: /health
              port: http
```

If `/health` fails repeatedly, kubelet restarts the container.

```yaml
          readinessProbe:
            httpGet:
              path: /health
              port: http
```

Until readiness passes, the Pod is removed from Service endpoints — no traffic to unready Pods.

---

## k8s/service.yaml

```yaml
spec:
  type: ClusterIP
  selector:
    app: course-nginx
```

Internal cluster IP only. `selector` must match Pod labels from the Deployment template.

```yaml
      targetPort: http
```

References the named port `http` on the container (port 80) — indirection avoids magic numbers.

---

## k8s/ingress.yaml (optional)

```yaml
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
```

AWS Load Balancer Controller creates an ALB. `target-type: ip` registers Pod IPs directly (common on EKS).

```yaml
  ingressClassName: alb
```

Selects the ALB ingress class installed by the controller.

---

## Apply Order

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Namespace first, then ConfigMap (referenced by Deployment), then workload and networking.

---

## Build and Push Commands

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker build -t course-nginx:v1 .
docker tag course-nginx:v1 "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/course-nginx:v1"
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/course-nginx:v1"
```

Update `deployment.yaml` image line with your account ID, then `kubectl apply -f k8s/deployment.yaml`.
