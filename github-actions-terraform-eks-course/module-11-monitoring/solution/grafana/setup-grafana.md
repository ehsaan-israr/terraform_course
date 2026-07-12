# Grafana Setup — Module 11

## Access Grafana

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Open http://localhost:3000

- **Username:** `admin`
- **Password:** Retrieve with:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

If using custom values password `changeme-use-secret-in-prod`, change immediately after first login.

## Verify Prometheus Datasource

1. **Connections → Data sources → Prometheus**
2. URL should be `http://kube-prometheus-stack-prometheus:9090`
3. Click **Save & test** — expect "Data source is working"

## Import Dashboard JSON

1. **Dashboards → New → Import**
2. Upload `grafana/dashboard-kubernetes-cluster.json`
3. Select Prometheus datasource
4. Click **Import**

## Useful Built-in Dashboards

The Helm chart installs default dashboards:

- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Node Exporter / Nodes

## Create Alert (Optional)

1. **Alerting → Alert rules → New alert rule**
2. Query: `rate(nginx_http_requests_total[5m])`
3. Condition: IS BELOW 0.001 for 5m (no traffic — demo only)

## Production Hardening

- Store admin password in External Secrets or Sealed Secrets
- Enable Grafana OIDC (GitHub, Google, AWS SSO)
- Use internal ingress with TLS instead of port-forward
