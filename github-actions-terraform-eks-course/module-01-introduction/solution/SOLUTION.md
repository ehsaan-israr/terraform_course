# Module 01 Solution: Toolchain Setup Scripts

This solution provides automated scripts to check prerequisites, install tools on Linux/macOS, and verify your environment. Read each section below to understand what every important line does.

---

## File Overview

| File | Purpose |
| --- | --- |
| `scripts/check-prerequisites.sh` | Read-only checks before installation |
| `scripts/install-linux.sh` | Installs tools on Debian/Ubuntu-based Linux |
| `scripts/install-macos.sh` | Installs tools via Homebrew on macOS |
| `scripts/verify-toolchain.sh` | Post-install validation (exit 0 = ready) |
| `verification-checklist.md` | Printable checklist for learners |

---

## `scripts/check-prerequisites.sh`

```bash
#!/usr/bin/env bash
```

Uses bash explicitly so behavior is consistent across macOS and Linux.

```bash
set -euo pipefail
```

- `set -e` — exit on first command failure.
- `set -u` — treat unset variables as errors.
- `set -o pipefail` — pipeline fails if any stage fails.

```bash
MIN_TF_VERSION="1.5.0"
MIN_KUBECTL_VERSION="1.28.0"
MIN_GIT_VERSION="2.30.0"
```

Centralized minimum versions; change here when course requirements update.

```bash
version_ge() {
  printf '%s\n%s\n' "$2" "$1" | sort -V -C
}
```

Compares semantic versions: returns success if `$1 >= $2` using `sort -V`.

```bash
check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  [FOUND] $cmd -> $(command -v "$cmd")"
    return 0
  else
    echo "  [MISSING] $cmd"
    return 1
  fi
}
```

`command -v` is POSIX-portable way to locate executables without running them.

---

## `scripts/install-linux.sh`

```bash
if [[ $EUID -ne 0 ]]; then
  echo "Re-run with sudo for system package installation."
  exit 1
fi
```

Package installs to `/usr` require root on Linux.

```bash
apt-get update -qq
apt-get install -y -qq curl unzip gnupg software-properties-common apt-transport-https ca-certificates
```

Quiet apt update/install of bootstrap dependencies.

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list
```

Adds HashiCorp's signed apt repository for official Terraform packages.

```bash
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
```

Downloads architecture-specific AWS CLI v2 bundle and installs to `/usr/local/aws-cli`.

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Kubernetes SIG packages for `kubectl` (version track v1.29).

---

## `scripts/install-macos.sh`

```bash
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew required. Install from https://brew.sh"
  exit 1
fi
```

macOS path assumes Homebrew; fails fast with clear message.

```bash
brew install git awscli kubectl
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Installs course tools from well-maintained formulae. Docker requires separate Docker Desktop install (cask not included to avoid GUI dependency in CI).

---

## `scripts/verify-toolchain.sh`

```bash
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
```

Counters produce a summary report at the end.

```bash
if aws sts get-caller-identity >/dev/null 2>&1; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  pass "AWS credentials valid (account: $ACCOUNT)"
else
  fail "AWS credentials not configured or expired"
fi
```

Validates **real** AWS auth, not just CLI presence.

```bash
if docker info >/dev/null 2>&1; then
  pass "Docker daemon is running"
else
  fail "Docker daemon not reachable (start Docker Desktop or docker service)"
fi
```

Distinguishes "docker installed" from "docker usable".

```bash
if [[ $FAIL -eq 0 ]]; then
  echo "  All checks passed. Toolchain ready."
  exit 0
else
  exit 1
fi
```

Non-zero exit enables CI and scripts to gate on readiness.

---

## Usage

```bash
# 1. Check what's missing
./scripts/check-prerequisites.sh

# 2. Install (pick your OS)
sudo ./scripts/install-linux.sh    # Linux
./scripts/install-macos.sh           # macOS

# 3. Configure AWS
aws configure   # or aws sso login

# 4. Verify everything
./scripts/verify-toolchain.sh
```

---

## Intentional Omissions

- No AWS credentials are stored in these scripts.
- Docker Desktop on macOS must be installed manually from docker.com.
- Windows native is unsupported; use WSL2 and `install-linux.sh`.
