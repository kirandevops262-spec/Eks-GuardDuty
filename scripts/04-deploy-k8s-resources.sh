#!/bin/bash
# ─────────────────────────────────────────────
# 04-deploy-k8s-resources.sh
# Deploys CloudWatch Container Insights + MCP Server to EKS
# ─────────────────────────────────────────────
set -euo pipefail

source "$(dirname "$0")/../.env" 2>/dev/null || true

CLUSTER_NAME=${EKS_CLUSTER_NAME:-eks-mcp-cluster}
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_URI="${ECR_REPO_URI:-${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME:-eks-mcp}-mcp-server}"
TF_DIR="$(dirname "$0")/../infrastructure/environments/dev"

echo "========================================"
echo " Deploying Kubernetes Resources"
echo "========================================"

# Get Terraform outputs
echo "→ Fetching Terraform outputs"
cd "$TF_DIR"
CLOUDWATCH_IRSA=$(terraform output -raw cloudwatch_irsa_role_arn 2>/dev/null || echo "")
MCP_IRSA=$(terraform output -raw mcp_irsa_role_arn 2>/dev/null || echo "")

# ── 1. CloudWatch Container Insights ──────────────────────
echo "→ Installing CloudWatch Container Insights"
ClusterName=$CLUSTER_NAME
RegionName=$REGION
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'

curl -s https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | \
  sed "s/{{cluster_name}}/$ClusterName/g;s/{{region_name}}/$RegionName/g;s/{{http_server_toggle}}/$FluentBitHttpPort/g;s/{{read_from_head}}/$FluentBitReadFromHead/g" | \
  kubectl apply -f -

echo "  ✓ Container Insights deployed"

# ── 2. Annotate CloudWatch ServiceAccount with IRSA ────────
if [[ -n "$CLOUDWATCH_IRSA" ]]; then
  kubectl annotate serviceaccount cloudwatch-agent \
    -n amazon-cloudwatch \
    eks.amazonaws.com/role-arn="$CLOUDWATCH_IRSA" \
    --overwrite
  echo "  ✓ CloudWatch IRSA annotated"
fi

# ── 3. MCP Server ──────────────────────────────────────────
echo "→ Deploying MCP Server"
cd "$(dirname "$0")/.."

# Substitute env vars in manifest
sed -e "s|\${ECR_REPO_URI}|${ECR_REPO_URI}|g" \
    -e "s|\${MCP_IRSA_ROLE_ARN}|${MCP_IRSA:-arn:aws:iam::${ACCOUNT_ID}:role/mcp-placeholder}|g" \
    -e "s|\${CLOUDWATCH_IRSA_ROLE_ARN}|${CLOUDWATCH_IRSA:-}|g" \
    k8s/mcp-server.yaml | kubectl apply -f -

echo "  ✓ MCP Server deployed"

# ── 4. Verify ──────────────────────────────────────────────
echo ""
echo "→ Waiting for MCP Server pods to be ready..."
kubectl rollout status deployment/mcp-server -n mcp-system --timeout=120s

echo ""
echo "========================================"
echo " Kubernetes resources deployed!"
kubectl get pods -n mcp-system
kubectl get pods -n amazon-cloudwatch
echo "========================================"
