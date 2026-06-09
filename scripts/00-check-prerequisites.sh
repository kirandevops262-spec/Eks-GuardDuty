#!/bin/bash
# ─────────────────────────────────────────────
# 00-check-prerequisites.sh
# Validates all required tools are installed
# ─────────────────────────────────────────────
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

pass() { echo -e "${GREEN}[✓]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; FAILED=1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

FAILED=0

echo "========================================"
echo " EKS + CloudWatch + GuardDuty MCP Setup"
echo " Prerequisite Check"
echo "========================================"

# --- Required Tools ---
for tool in aws terraform kubectl helm python3 pip3 git jq curl; do
  if command -v "$tool" &>/dev/null; then
    pass "$tool: $(command -v $tool)"
  else
    fail "$tool is NOT installed"
  fi
done

# --- AWS CLI version ---
AWS_VER=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
if [[ "${AWS_VER%%.*}" -ge 2 ]]; then
  pass "AWS CLI v2 ($AWS_VER)"
else
  warn "AWS CLI v1 detected — recommend upgrading to v2"
fi

# --- AWS credentials ---
if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  REGION=$(aws configure get region || echo "not set")
  pass "AWS credentials valid — Account: $ACCOUNT | Region: $REGION"
else
  fail "AWS credentials NOT configured. Run: aws configure"
fi

# --- Terraform version ---
TF_VER=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)
pass "Terraform: $TF_VER"

# --- Python version ---
PY_VER=$(python3 --version 2>&1)
pass "$PY_VER"

# --- eksctl (optional but recommended) ---
if command -v eksctl &>/dev/null; then
  pass "eksctl: $(eksctl version)"
else
  warn "eksctl not found — optional but useful for EKS debugging"
fi

echo "========================================"
if [[ $FAILED -eq 1 ]]; then
  echo -e "${RED}Some prerequisites are missing. Fix above errors first.${NC}"
  exit 1
else
  echo -e "${GREEN}All prerequisites satisfied!${NC}"
fi
