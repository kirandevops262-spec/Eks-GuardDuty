#!/bin/bash
# ─────────────────────────────────────────────
# deploy-all.sh
# MASTER SCRIPT — runs full end-to-end setup
# Usage: ./deploy-all.sh
# ─────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() { echo -e "\n${BLUE}════════════════════════════════════════${NC}"; echo -e "${BLUE} $1${NC}"; echo -e "${BLUE}════════════════════════════════════════${NC}"; }
ok()     { echo -e "${GREEN}[✓]${NC} $1"; }
step()   { echo -e "${YELLOW}[→]${NC} $1"; }

# ── Sanity checks ──────────────────────────────────────────
if [[ ! -f "$SCRIPT_DIR/../.env" ]]; then
  echo -e "${RED}ERROR: .env file not found.${NC}"
  echo "Copy .env.example → .env and fill in your values."
  exit 1
fi
source "$SCRIPT_DIR/../.env"

banner "Step 0: Prerequisite Check"
bash "$SCRIPT_DIR/00-check-prerequisites.sh"
ok "Prerequisites OK"

banner "Step 1: Bootstrap Remote State"
bash "$SCRIPT_DIR/01-bootstrap-remote-state.sh"
ok "Remote state ready"

banner "Step 2: Deploy AWS Infrastructure"
bash "$SCRIPT_DIR/02-deploy-infrastructure.sh"
ok "Infrastructure deployed"

banner "Step 3: Setup MCP Server IRSA"
bash "$SCRIPT_DIR/05-setup-mcp-irsa.sh"
ok "IRSA configured"

banner "Step 4: Build & Push MCP Server Image"
bash "$SCRIPT_DIR/03-build-push-mcp-server.sh"
ok "Docker image pushed to ECR"

banner "Step 5: Deploy Kubernetes Resources"
bash "$SCRIPT_DIR/04-deploy-k8s-resources.sh"
ok "Kubernetes resources deployed"

banner "Deployment Complete!"
echo ""
echo "  Cluster:     ${EKS_CLUSTER_NAME}"
echo "  Region:      ${AWS_REGION}"
echo "  MCP Pods:    $(kubectl get pods -n mcp-system --no-headers 2>/dev/null | wc -l | tr -d ' ') running"
echo ""
echo -e "${GREEN}MCP Server is live in your EKS cluster!${NC}"
echo ""
echo "  Test it locally:"
echo "    kubectl port-forward svc/mcp-server 8080:80 -n mcp-system"
echo ""
echo "  View logs:"
echo "    kubectl logs -l app=mcp-server -n mcp-system -f"
echo ""
echo "  CloudWatch Dashboard:"
echo "    https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${PROJECT_NAME}-dashboard"
