# Module 11 Solution — Line-by-Line Explanation

## Helm Values (`helm/kube-prometheus-stack-values.yaml`)

| Key | Purpose |
| --- | --- |
| `prometheus.prometheusSpec.retention` | Keep 7 days of metrics (adjust for cost) |
| `serviceMonitorSelectorNilUsesHelmValues: false` | Prometheus discovers **all** ServiceMonitors in cluster, not only chart-owned ones |
| `grafana.service.type: ClusterIP` | No public exposure — access via port-forward or private ingress |
| `grafana.adminPassword` | Initial password — **change in production**; use existing secret instead |
| `defaultRules.create` | Installs standard Kubernetes alerting rules |

## Sample App (`kubernetes/sample-app-metrics.yaml`)

- **nginx container** — Serves HTTP on port 80.
- **nginx-prometheus-exporter sidecar** — Exposes `/metrics` on port `9113` named `metrics`.
- **Service** — Two ports: `http` and `metrics` — ServiceMonitor references `metrics` port name.

## ServiceMonitor (`servicemonitor-sample-app.yaml`)

| Field | Purpose |
| --- | --- |
| `namespace: monitoring` | Where CR lives (can differ from target) |
| `labels.release: kube-prometheus-stack` | Matches Prometheus operator release selector |
| `namespaceSelector.matchNames: [default]` | Scrape services only in `default` namespace |
| `selector.matchLabels.app: sample-app` | Matches Service labels |
| `endpoints.port: metrics` | Named port on the Service |
| `interval: 30s` | Scrape frequency |

## Fluent Bit

### ConfigMap

- **INPUT tail** — Reads `/var/log/containers/*.log` (symlinks to pod logs).
- **FILTER kubernetes** — Enriches logs with pod metadata (pod name, namespace, labels).
- **OUTPUT cloudwatch_logs** — Ships to `/aws/eks/gha-terraform-eks/application` in `us-east-1`.
- **`auto_create_group: true`** — Creates log group if missing (disable in prod if pre-provisioned).

### DaemonSet

- **`aws-for-fluent-bit:2.2.0`** — AWS-maintained image with CloudWatch plugin.
- **hostPath mounts** — Required to read node container logs.
- **IRSA** — `ServiceAccount` annotation `eks.amazonaws.com/role-arn` supplies credentials.

### `cloudwatch-iam.md`

Documents trust policy binding role to `system:serviceaccount:amazon-cloudwatch:fluent-bit`.

## Kubernetes Dashboard

- **`dashboard-viewer` ServiceAccount** — Not cluster-admin.
- **ClusterRole** — Only `get`, `list`, `watch` on common resources.
- **ClusterIP Service** — Access via `kubectl proxy` only.
- **Image `kubernetesui/dashboard:v2.7.0`** — Pinned version.

## Grafana Dashboard JSON

Three panels:

1. CPU by namespace — `container_cpu_usage_seconds_total`
2. Memory by namespace — `container_memory_working_set_bytes`
3. Sample app nginx requests — `nginx_http_requests_total`

Import via Grafana UI; `${DS_PROMETHEUS}` variable selects datasource at import time.

## GitHub Actions Workflow

| Step | Purpose |
| --- | --- |
| `configure-aws-credentials` | OIDC role with EKS access |
| `aws eks update-kubeconfig` | kubectl context for cluster |
| `azure/setup-helm@v4` | Pinned Helm 3.14.4 |
| `helm upgrade --install` | Idempotent chart install with `--version` pin |
| `kubectl apply` fluent-bit | Deploy logging after metrics stack healthy |

Set `CLUSTER_NAME` and `AWS_EKS_DEPLOY_ROLE_ARN` secret to match your environment.
