#!/usr/bin/env bash
# Post-install verification — exit 0 when toolchain is course-ready.
set -euo pipefail

MIN_TF_VERSION="1.5.0"
MIN_KUBECTL_VERSION="1.28.0"
MIN_GIT_VERSION="2.30.0"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

version_ge() {
  printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

echo "========================================"
echo "  Course Toolchain Verification"
echo "========================================"
echo ""

# --- Git ---
if command -v git >/dev/null 2>&1; then
  GIT_VER=$(git --version | awk '{print $3}')
  if version_ge "$GIT_VER" "$MIN_GIT_VERSION"; then
    pass "Git $GIT_VER"
  else
    fail "Git $GIT_VER (need >= $MIN_GIT_VERSION)"
  fi
else
  fail "Git not found"
fi

# --- AWS CLI ---
if command -v aws >/dev/null 2>&1; then
  pass "AWS CLI installed ($(aws --version 2>&1 | cut -d' ' -f1))"
else
  fail "AWS CLI not found"
fi

# --- AWS credentials ---
if aws sts get-caller-identity >/dev/null 2>&1; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  REGION="${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null || echo 'not-set')}"
  pass "AWS credentials valid (account: $ACCOUNT, region: $REGION)"
else
  fail "AWS credentials not configured or expired"
fi

# --- Terraform ---
if command -v terraform >/dev/null 2>&1; then
  TF_VER=$(terraform version | head -1 | awk '{print $2}' | sed 's/v//')
  if version_ge "$TF_VER" "$MIN_TF_VERSION"; then
    pass "Terraform $TF_VER"
  else
    fail "Terraform $TF_VER (need >= $MIN_TF_VERSION)"
  fi
else
  fail "Terraform not found"
fi

# --- kubectl ---
if command -v kubectl >/dev/null 2>&1; then
  KUBE_VER=$(kubectl version --client 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/v//')
  if [[ -n "$KUBE_VER" ]] && version_ge "$KUBE_VER" "$MIN_KUBECTL_VERSION"; then
    pass "kubectl $KUBE_VER"
  else
    fail "kubectl version could not be verified (need >= $MIN_KUBECTL_VERSION)"
  fi
else
  fail "kubectl not found"
fi

# --- Docker ---
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    pass "Docker daemon is running"
  else
    fail "Docker installed but daemon not reachable"
  fi
else
  fail "Docker not found"
fi

# --- Docker hello-world (optional quick functional test) ---
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  if docker run --rm hello-world >/dev/null 2>&1; then
    pass "docker run hello-world succeeded"
  else
    fail "docker run hello-world failed"
  fi
fi

echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"

if [[ $FAIL -eq 0 ]]; then
  echo "  All checks passed. Toolchain ready."
  exit 0
else
  echo "  Fix failures above before starting Module 02."
  exit 1
fi
