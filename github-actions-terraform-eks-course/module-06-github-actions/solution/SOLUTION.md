# Module 06 Solution — Line-by-Line Explanation

---

## hello.yml

### Triggers

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      name:
```

Three event types: CI on push/PR to `main`, plus manual runs with an optional `name` input (`github.event.inputs.name`).

### Permissions and concurrency

```yaml
permissions:
  contents: read
```

Read-only token — sufficient for checkout and echo steps.

```yaml
concurrency:
  group: hello-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

Cancels older runs on the same branch when a new push arrives — saves minutes and avoids stale results.

### Environment variables

```yaml
env:
  GLOBAL_GREETING: "Hello, GitHub Actions!"
  AWS_REGION: us-east-1
```

Workflow-level `env` applies to all jobs. Individual jobs and steps can override.

```yaml
    env:
      JOB_ENV: course-module-06
```

Job-level env scopes to that job's steps.

### Steps

```yaml
      - uses: actions/checkout@v4
```

Checks out the commit that triggered the workflow — required before reading repo files.

```yaml
      - name: Show region from repository variable
        env:
          REGION: ${{ vars.AWS_REGION }}
```

`vars.*` reads **repository/org/environment variables** (non-secret). Fallback in shell uses workflow `env.AWS_REGION`.

```yaml
      - name: Greet using secret (masked)
        env:
          GREETING_NAME: ${{ secrets.COURSE_GREETING_NAME }}
          INPUT_NAME: ${{ github.event.inputs.name }}
        run: |
          TARGET="${INPUT_NAME:-${GREETING_NAME:-Learner}}"
```

Secrets are injected as env vars and **masked** in logs. Manual input takes precedence over secret, then default `Learner`.

```yaml
        if: github.event_name == 'workflow_dispatch'
```

Conditional step — runs only for manual triggers. Demonstrates `if:` expressions.

### Job dependency

```yaml
  post-greet:
    needs: greet
```

`needs` enforces job order — `post-greet` starts only after `greet` succeeds.

---

## lint.yml

### Path filters

```yaml
  pull_request:
    paths:
      - "**.js"
```

Limits runs to PRs that touch matching paths — reduces noise and cost.

### Matrix

```yaml
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest]
        node-version: [18, 20, 22]
```

Creates three jobs (one per Node version). `fail-fast: false` lets all versions finish even if one fails.

### Setup Node

```yaml
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
```

Installs the matrix Node version on the runner.

### Placeholder lint

The `echo "Lint OK"` step stands in for `npm run lint` until Module 07 adds application code. Swap when `package.json` exists.

---

## GitHub UI Configuration

| Name | Type | Location | Example value |
| --- | --- | --- | --- |
| `COURSE_GREETING_NAME` | Secret | Settings → Secrets → Actions | `Ada` |
| `AWS_REGION` | Variable | Settings → Variables → Actions | `us-east-1` |

Never commit these values to the repository.
