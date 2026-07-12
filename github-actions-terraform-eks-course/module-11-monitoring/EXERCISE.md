# Module 11 Exercise: EKS Monitoring Stack

## Objective

Deploy a complete observability stack on your EKS cluster: **Prometheus**, **Grafana**, **Kubernetes Dashboard**, application metrics via **ServiceMonitor**, and **log forwarding** to Amazon CloudWatch Logs.

## Requirements

1. **Prometheus & Grafana**
   - Install `kube-prometheus-stack` via Helm in namespace `monitoring`.
   - Custom `values.yaml` with resource limits appropriate for a small cluster.
   - Retain default Kubernetes dashboards; document Grafana admin access.

2. **Application metrics**
   - Deploy or update sample app exposing `/metrics` on a named port `metrics`.
   - Create `ServiceMonitor` scraping every 30s.
   - Verify target is UP in Prometheus.

3. **Kubernetes Dashboard**
   - Deploy official dashboard with a dedicated namespace.
   - Create ServiceAccount with **read-only** ClusterRole (get/list/watch).
   - Document access via `kubectl proxy` (no public LoadBalancer).

4. **Logging**
   - Deploy Fluent Bit (DaemonSet) forwarding to CloudWatch Logs in `us-east-1`.
   - Use IRSA for AWS credentials (no static keys in manifests).
   - Log group naming: `/aws/eks/<cluster-name>/application`.

5. **CI/CD (optional)**
   - Workflow `deploy-monitoring.yml` applying Helm and manifests on push to `main`.

6. **Grafana dashboard**
   - Provide `dashboard-kubernetes-cluster.json` OR `setup-grafana.md` with import steps.

## Constraints

- Region: `us-east-1`.
- Do not expose Grafana or Dashboard via public `LoadBalancer` without authentication.
- Pin Helm chart version in workflow or document exact version used.
- Fluent Bit must use IRSA — no `AWS_ACCESS_KEY_ID` in ConfigMap.
- Resource requests must be set for Prometheus and Grafana pods.

## Tasks

### Task 1: Helm Values

Create `helm/kube-prometheus-stack-values.yaml` with prometheus and grafana resource limits, persistence disabled (for cost), and `serviceMonitorSelectorNilUsesHelmValues: false` if needed for custom monitors.

### Task 2: ServiceMonitor

Write manifests for metrics-enabled sample app and ServiceMonitor with correct labels for the Prometheus release.

### Task 3: Fluent Bit

Write ConfigMap (parsers, outputs), DaemonSet, ServiceAccount, and document IAM trust policy for IRSA.

### Task 4: Kubernetes Dashboard

Deploy dashboard components with read-only RBAC and document token retrieval for login.

### Task 5: Verify End-to-End

Document commands to port-forward Prometheus and Grafana; CloudWatch Logs Insights query for app logs.

### Task 6: GitHub Actions

Automate `helm upgrade --install` and `kubectl apply` with EKS credentials via OIDC.

## Expected Deliverables

| Deliverable | Path |
| --- | --- |
| Helm values | `helm/kube-prometheus-stack-values.yaml` |
| ServiceMonitor + app | `kubernetes/servicemonitor-*.yaml`, `sample-app-metrics.yaml` |
| Fluent Bit | `kubernetes/fluent-bit/*` |
| K8s Dashboard | `kubernetes/kubernetes-dashboard.yaml` |
| Grafana assets | `grafana/dashboard-*.json` or `setup-grafana.md` |
| CD workflow | `.github/workflows/deploy-monitoring.yml` |

## Validation Checklist

- [ ] All pods in `monitoring` namespace are Running.
- [ ] Prometheus shows `sample-app` target as UP.
- [ ] Grafana login works; Prometheus datasource tests successfully.
- [ ] Kubernetes Dashboard loads via kubectl proxy with read-only SA.
- [ ] CloudWatch log group receives new log events from sample app pods.
- [ ] Fluent Bit pods Running on each node (or one per node in DaemonSet).
- [ ] No public LoadBalancer services for Grafana or Dashboard.
- [ ] ServiceMonitor has label matching Prometheus operator selector.
- [ ] IAM role trust policy allows OIDC from EKS service account.
- [ ] Helm chart version documented in README or workflow.
