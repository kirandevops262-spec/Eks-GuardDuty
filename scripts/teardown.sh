#!/bin/bash
# ─────────────────────────────────────────────
# teardown.sh
# Destroys ALL resources in reverse order
# ─────────────────────────────────────────────
set -euo pipefail

source "$(dirname "$0")/../.env" 2>/dev/null || true

RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${RED}========================================"
echo " WARNING: This will DESTROY everything"
echo " Project: ${PROJECT_NAME:-eks-mcp}"
echo " Cluster: ${EKS_CLUSTER_NAME:-eks-mcp-cluster}"
echo -e "========================================${NC}"
read -p "Type 'destroy' to confirm: " CONFIRM
[[ "$CONFIRM" != "destroy" ]] && echo "Aborted." && exit 0

# 1. Remove k8s resources first
echo -e "${YELLOW}→ Removing Kubernetes resources${NC}"
kubectl delete namespace mcp-system --ignore-not-found
kubectl delete namespace amazon-cloudwatch --ignore-not-found

# 2. Terraform destroy
echo -e "${YELLOW}→ Running terraform destroy${NC}"
cd "$(dirname "$0")/../infrastructure/environments/dev"
terraform destroy -auto-approve

# 3. Delete ECR images
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO="${PROJECT_NAME:-eks-mcp}-mcp-server"
echo -e "${YELLOW}→ Deleting ECR repository: $REPO${NC}"
aws ecr delete-repository --repository-name "$REPO" \
  --region "${AWS_REGION:-us-east-1}" --force 2>/dev/null || true

echo ""
echo "All resources destroyed."
