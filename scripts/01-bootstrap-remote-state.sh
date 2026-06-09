#!/bin/bash
# ─────────────────────────────────────────────
# 01-bootstrap-remote-state.sh
# Creates S3 bucket + DynamoDB table for Terraform remote state
# Run ONCE before terraform init
# ─────────────────────────────────────────────
set -euo pipefail

source "$(dirname "$0")/../.env" 2>/dev/null || true

PROJECT=${PROJECT_NAME:-eks-mcp}
REGION=${AWS_REGION:-us-east-1}
BUCKET="${PROJECT}-tfstate-$(aws sts get-caller-identity --query Account --output text)"
TABLE="${PROJECT}-tfstate-lock"

echo "→ Creating S3 bucket: $BUCKET"
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "  Bucket already exists, skipping"
else
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  echo "  ✓ S3 bucket created"
fi

echo "→ Creating DynamoDB table: $TABLE"
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" &>/dev/null; then
  echo "  Table already exists, skipping"
else
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  echo "  ✓ DynamoDB table created"
fi

echo ""
echo "========================================"
echo "Now uncomment the backend block in:"
echo "  infrastructure/environments/dev/provider.tf"
echo "and set bucket = \"$BUCKET\""
echo "========================================"
