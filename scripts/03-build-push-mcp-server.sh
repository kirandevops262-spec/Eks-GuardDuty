#!/bin/bash
# ─────────────────────────────────────────────
# 03-build-push-mcp-server.sh
# Builds Docker image and pushes to ECR
# ─────────────────────────────────────────────
set -euo pipefail

source "$(dirname "$0")/../.env" 2>/dev/null || true

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-us-east-1}
PROJECT=${PROJECT_NAME:-eks-mcp}
REPO_NAME="${PROJECT}-mcp-server"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"
IMAGE_TAG="latest"

echo "========================================"
echo " Building & Pushing MCP Server to ECR"
echo "========================================"

# Create ECR repo if it doesn't exist
echo "→ Ensuring ECR repository exists: $REPO_NAME"
aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" &>/dev/null || \
  aws ecr create-repository --repository-name "$REPO_NAME" --region "$REGION" \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256

# Docker login to ECR
echo "→ Logging in to ECR"
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Build image
echo "→ Building Docker image"
docker build -t "${REPO_NAME}:${IMAGE_TAG}" \
  "$(dirname "$0")/../mcp-server"

# Tag and push
docker tag "${REPO_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"
echo "→ Pushing to ECR: ${ECR_URI}:${IMAGE_TAG}"
docker push "${ECR_URI}:${IMAGE_TAG}"

echo ""
echo "========================================"
echo " Image pushed: ${ECR_URI}:${IMAGE_TAG}"
echo " Export this for k8s deploy:"
echo "   export ECR_REPO_URI=${ECR_URI}"
echo "========================================"

export ECR_REPO_URI="${ECR_URI}"
