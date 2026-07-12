# Module 06 Exercise — GitHub Actions Fundamentals

## Objective

Create two GitHub Actions workflows that demonstrate core concepts: triggers, jobs, steps, environment variables, secrets, matrix builds, and least-privilege permissions.

---

## Requirements

1. **`hello.yml`** — a workflow named `Hello Workflow` that:
   - Triggers on `push` to `main`, `workflow_dispatch` (with optional string input `name`), and `pull_request`
   - Defines one job `greet` on `ubuntu-latest`
   - Checks out the repository
   - Prints a greeting using a shell step
   - Reads a repository **secret** (e.g., `COURSE_GREETING_NAME`) without echoing its value in plaintext
   - Reads a repository **variable** (e.g., `AWS_REGION` = `us-east-1`)
   - Sets job-level `env` and step-level `env` demonstrating precedence

2. **`lint.yml`** — a workflow named `Lint Workflow` that:
   - Triggers on `pull_request` to `main` (paths: `**.js`, `**.json`, `**.yml`, or your choice)
   - Uses `permissions: contents: read`
   - Defines job `lint` with a **matrix** over `node-version: [18, 20, 22]` on `ubuntu-latest`
   - Checks out code, sets up Node.js, runs `node --version` and a placeholder lint command (e.g., `echo "Lint OK"` or `npm run lint` if you add a package)
   - Uses `concurrency` to cancel in-progress runs for the same PR

3. Document in `WORKFLOWS.md` (in your repo root or module folder):
   - What triggers each workflow
   - Where secrets vs variables are configured in GitHub UI
   - Security notes (no hardcoded credentials)

---

## Constraints

- Use **pinned action versions** (e.g., `actions/checkout@v4`, not `@main`).
- Do **not** commit real secrets — use GitHub Settings only.
- Set explicit `permissions` on workflows that don't need write access.
- Use `us-east-1` as the example AWS region variable (for consistency with the course).
- Workflows must be valid YAML (test by pushing to GitHub).

---

## Tasks

### Task 1 — Hello workflow

- [ ] Create `.github/workflows/hello.yml`
- [ ] Add three trigger types: `push`, `pull_request`, `workflow_dispatch`
- [ ] Implement checkout + greeting steps
- [ ] Reference `${{ secrets.COURSE_GREETING_NAME }}` safely
- [ ] Reference `${{ vars.AWS_REGION }}`
- [ ] Run manually from Actions tab and confirm success

### Task 2 — Lint workflow with matrix

- [ ] Create `.github/workflows/lint.yml`
- [ ] Configure PR-only trigger with path filters
- [ ] Add matrix for Node 18, 20, 22
- [ ] Add `concurrency: group: lint-${{ github.ref }}`
- [ ] Verify three matrix jobs run on a test PR

### Task 3 — Secrets and variables lab

- [ ] Add repository secret `COURSE_GREETING_NAME`
- [ ] Add repository variable `AWS_REGION=us-east-1`
- [ ] Confirm secret masking in logs (`***`)

### Task 4 — Optional enhancements

- [ ] Add job `needs` dependency (second job runs after first)
- [ ] Add `if:` condition on a step (`github.event_name == 'workflow_dispatch'`)
- [ ] Install and run `actionlint` locally on workflow files

---

## Expected Deliverables

| Deliverable | Path |
| --- | --- |
| Hello workflow | `.github/workflows/hello.yml` |
| Lint workflow | `.github/workflows/lint.yml` |
| Documentation | `WORKFLOWS.md` |
| Green Actions runs | Screenshots or links in WORKFLOWS.md (optional) |

---

## Validation Checklist

- [ ] Both workflows appear under the Actions tab
- [ ] `Hello Workflow` succeeds on manual dispatch
- [ ] `Lint Workflow` runs on pull request with matrix (3 jobs)
- [ ] No plaintext secrets in workflow logs
- [ ] `permissions: contents: read` present on lint workflow
- [ ] Action references use version tags (`@v4`), not floating branches
- [ ] `workflow_dispatch` input documented in WORKFLOWS.md
- [ ] Concurrency group prevents duplicate PR runs
- [ ] YAML validates (no workflow parse errors on GitHub)

**Do not read `solution/` until all items are checked.**
