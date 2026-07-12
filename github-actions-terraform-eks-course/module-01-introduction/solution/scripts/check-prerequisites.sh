#!/usr/bin/env bash
# Read-only prerequisite check — does not install anything.
set -euo pipefail

MIN_TF_VERSION="1.5.0"
MIN_KUBECTL_VERSION="1.28.0"
MIN_GIT_VERSION="2.30.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

version_ge() {
  printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "  ${GREEN}[FOUND]${NC} $cmd -> $(command -v "$cmd")"
    return 0
  else
    echo -e "  ${RED}[MISSING]${NC} $cmd"
    return 1
  fi
}

check_version() {
  local label="$1"
  local current="$2"
  local minimum="$3"
  if version_ge "$current" "$minimum"; then
    echo -e "  ${GREEN}[OK]${NC} $label $current (>= $minimum)"
    return 0
  else
    echo -e "  ${YELLOW}[OLD]${NC} $label $current (need >= $minimum)"
    return 1
  fi
}

echo "========================================"
echo "  Course Toolchain — Prerequisite Check"
echo "========================================"
echo ""

MISSING=0

echo "Required commands:"
for cmd in git aws terraform kubectl docker; do
  check_cmd "$cmd" || MISSING=$((MISSING + 1))
done
echo ""

echo "Version checks (when installed):"
if command -v git >/dev/null 2>&1; then
  GIT_VER=$(git --version | awk '{print $3}')
  check_version "Git" "$GIT_VER" "$MIN_GIT_VERSION" || MISSING=$((MISSING + 1))
fi

if command -v aws >/dev/null 2>&1; then
  AWS_VER=$(aws --version 2>&1 | cut -d' ' -f1 | sed 's/aws-cli\///')
  echo -e "  ${GREEN}[OK]${NC} AWS CLI $AWS_VER"
fi

if command -v terraform >/dev/null 2>&1; then
  TF_VER=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
  if [[ -z "$TF_VER" ]]; then
    TF_VER=$(terraform version | head -1 | awk '{print $2}' | sed 's/v//')
  fi
  check_version "Terraform" "$TF_VER" "$MIN_TF_VERSION" || MISSING=$((MISSING + 1))
fi

if command -v kubectl >/dev/null 2>&1; then
  KUBE_VER=$(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion": "[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/v//')
  if [[ -z "$KUBE_VER" ]]; then
    KUBE_VER=$(kubectl version --client 2>/dev/null | grep -o 'v[0-9.]*' | head -1 | sed 's/v//')
  fi
  check_version "kubectl" "$KUBE_VER" "$MIN_KUBECTL_VERSION" || MISSING=$((MISSING + 1))
fi

echo ""
echo "AWS authentication:"
if aws sts get-caller-identity >/dev/null 2>&1; then
  echo -e "  ${GREEN}[OK]${NC} Credentials configured"
  aws sts get-caller-identity --output table
else
  echo -e "  ${RED}[FAIL]${NC} Run: aws configure  OR  aws sso login"
  MISSING=$((MISSING + 1))
fi

echo ""
if [[ $MISSING -eq 0 ]]; then
  echo -e "${GREEN}All prerequisites met.${NC}"
  exit 0
else
  echo -e "${YELLOW}$MISSING issue(s) found. Run install script or fix manually.${NC}"
  exit 1
fi
