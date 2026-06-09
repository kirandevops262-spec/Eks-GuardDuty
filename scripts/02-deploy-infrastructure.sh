#!/bin/bash
# ─────────────────────────────────────────────
# 02-deploy-infrastructure.sh
# Runs Terraform init → plan → apply
# ─────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/../infrastructure/environments/dev"

echo "========================================"
echo " Deploying Infrastructure via Terraform"
echo "========================================"

cd "$TF_DIR"

echo "→ terraform init"
terraform init -upgrade

echo "→ terraform validate"
terraform validate

echo "→ terraform plan"
terraform plan -out=tfplan

echo ""
read -p "Apply this plan? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

echo "→ terraform apply"
terraform apply tfplan

echo ""
echo "→ Capturing outputs..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "${AWS_REGION:-us-east-1}")

echo "========================================"
echo " Infrastructure deployed successfully!"
echo " Cluster: $CLUSTER_NAME"
echo "========================================"

# Update kubeconfig automatically
echo "→ Updating kubeconfig for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
echo "  ✓ kubeconfig updated"

kubectl get nodes
