#!/bin/bash
# ─────────────────────────────────────────────
# 05-setup-mcp-irsa.sh
# Creates IAM Role + Policy for MCP Server IRSA
# ─────────────────────────────────────────────
set -euo pipefail

source "$(dirname "$0")/../.env" 2>/dev/null || true

CLUSTER_NAME=${EKS_CLUSTER_NAME:-eks-mcp-cluster}
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT=${PROJECT_NAME:-eks-mcp}
ROLE_NAME="${PROJECT}-mcp-server-irsa"
POLICY_NAME="${PROJECT}-mcp-server-policy"
NAMESPACE="mcp-system"
SERVICE_ACCOUNT="mcp-server"

echo "========================================"
echo " Setting up MCP Server IRSA"
echo "========================================"

# Get OIDC provider
OIDC_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" \
  --query "cluster.identity.oidc.issuer" --output text)
OIDC_ID=${OIDC_URL##*/}
OIDC_PROVIDER="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}"

echo "→ OIDC Provider: $OIDC_PROVIDER"

# Create IAM policy
echo "→ Creating IAM policy: $POLICY_NAME"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document "file://$(dirname "$0")/../infrastructure/mcp-server-policy.json" \
  2>/dev/null || echo "  Policy already exists"

# Trust policy
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "${OIDC_PROVIDER}"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}",
        "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}:aud": "sts.amazonaws.com"
      }
    }
  }]
}
EOF
)

# Create IAM role
echo "→ Creating IAM role: $ROLE_NAME"
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "$TRUST_POLICY" \
  2>/dev/null || echo "  Role already exists"

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "$POLICY_ARN"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo "  ✓ Role ARN: $ROLE_ARN"

# Annotate service account in k8s
kubectl annotate serviceaccount "$SERVICE_ACCOUNT" \
  -n "$NAMESPACE" \
  eks.amazonaws.com/role-arn="$ROLE_ARN" \
  --overwrite 2>/dev/null || echo "  (ServiceAccount not yet created — will be annotated during k8s deploy)"

echo ""
echo "Export for use in k8s deployment:"
echo "  export MCP_IRSA_ROLE_ARN=$ROLE_ARN"
export MCP_IRSA_ROLE_ARN="$ROLE_ARN"
