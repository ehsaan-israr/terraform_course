# Module 07 Solution — Line-by-Line Explanation

---

## package.json

```json
"type": "module"
```

Enables ES modules (`import`/`export`) — matches modern Node and Jest/supertest usage.

```json
"test": "node --test test/**/*.test.js"
```

Uses Node 20 built-in test runner — no Jest config required.

---

## src/server.js

```javascript
const PORT = Number(process.env.PORT) || 3000;
```

Reads `PORT` from environment (Kubernetes sets this in Module 08).

```javascript
app.get("/health", (_req, res) => {
  res.status(200).json({ status: "healthy", service: "course-api" });
});
```

Health endpoint for probes and load balancers.

```javascript
if (process.env.NODE_ENV !== "test") {
  app.listen(PORT, "0.0.0.0", () => { ... });
}
export default app;
```

Skips binding a port during tests (supertest attaches directly). `export default` enables test imports.

---

## test/server.test.js

```javascript
import request from "supertest";
import app from "../src/server.js";
```

In-process HTTP tests without starting a real server on a port.

---

## Dockerfile

### Stage: deps

```dockerfile
RUN npm ci --omit=dev
```

Production dependencies only — smaller runtime layer.

### Stage: build

```dockerfile
RUN npm ci
COPY test ./test
RUN npm test
```

Tests run **during image build** — fails the build if tests fail (optional pattern; CI also tests separately).

### Stage: production

```dockerfile
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001 -G nodejs
USER nodejs
```

Non-root container user — security best practice on EKS.

```dockerfile
HEALTHCHECK ... wget -qO- http://127.0.0.1:3000/health
```

Docker-level health check; Kubernetes probes added in Module 08.

---

## .github/workflows/ci.yml

### Job: test

```yaml
permissions:
  contents: read
```

Minimal permissions for checkout and npm.

```yaml
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: npm
```

Caches npm dependencies between runs.

### Job: docker

```yaml
    needs: test
    if: github.event_name == 'push'
```

Docker push runs only after tests pass, and only on push (not every PR) to avoid unreviewed image publishes. Adjust policy per team (some teams push PR images to a sandbox ECR).

```yaml
    permissions:
      id-token: write
```

Required for GitHub to mint OIDC JWT for AWS STS.

```yaml
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
```

Exchanges OIDC token for temporary AWS credentials — no static keys.

```yaml
      - uses: aws-actions/amazon-ecr-login@v2
```

Authenticates Docker to ECR registry.

```yaml
          docker build -t "${IMAGE_URI}:${IMAGE_TAG}" -t "${IMAGE_URI}:latest" .
          docker push "${IMAGE_URI}:${IMAGE_TAG}"
```

Tags image with immutable `GITHUB_SHA` for traceability plus `latest` on main.

---

## docs/aws-oidc-setup.md

Documents IAM OIDC provider, trust policy `sub` claim scoping, ECR IAM policy, and access-key alternative with security warnings.
