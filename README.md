# EKS + CloudWatch + GuardDuty MCP Server

A production-grade MCP (Model Context Protocol) server that gives AI assistants real-time access to your AWS EKS cluster health, CloudWatch metrics/logs, and GuardDuty security findings.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   AWS Account                   │
│                                                 │
│  ┌──────────┐    ┌─────────────────────────┐   │
│  │  VPC     │    │   EKS Cluster           │   │
│  │ 3 AZs    │───▶│   ┌─────────────────┐   │   │
│  │ Public + │    │   │  MCP Server Pod │   │   │
│  │ Private  │    │   │  (x2 replicas)  │   │   │
│  │ Subnets  │    │   └────────┬────────┘   │   │
│  └──────────┘    │            │ IRSA        │   │
│                  │   ┌────────▼────────┐   │   │
│                  │   │ CW Agent DaemonS│   │   │
│                  └───┴─────────────────┘   │   │
│                                            │   │
│  ┌─────────────┐  ┌──────────────────┐    │   │
│  │  GuardDuty  │  │   CloudWatch     │    │   │
│  │  Detector   │  │   Logs/Metrics   │    │   │
│  │  + SNS Alerts│ │   Alarms/Dashboard│   │   │
│  └─────────────┘  └──────────────────┘    │   │
│                                            │   │
│  ┌─────────────┐  ┌──────────────────┐    │   │
│  │  ECR        │  │  S3 + DynamoDB   │    │   │
│  │  (Docker)   │  │  (TF State)      │    │   │
│  └─────────────┘  └──────────────────┘    │   │
└─────────────────────────────────────────────────┘
```

---

## Prerequisites

| Tool        | Version    | Install |
|-------------|------------|---------|
| AWS CLI     | v2+        | `brew install awscli` |
| Terraform   | >= 1.5     | `brew install terraform` |
| kubectl     | >= 1.27    | `brew install kubectl` |
| Helm        | >= 3.12    | `brew install helm` |
| Docker      | Desktop    | `brew install --cask docker` |
| Python      | 3.11+      | `brew install python` |
| jq          | any        | `brew install jq` |

---

## Quick Start (Full Automation)

```bash
# 1. Clone and enter project
cd /path/to/Eks-GuardDuty

# 2. Configure AWS credentials
aws configure

# 3. Copy and edit environment file
cp .env.example .env
# Edit .env with your AWS_REGION, PROJECT_NAME, etc.

# 4. Run master deploy script
./scripts/deploy-all.sh
```

That's it. The master script handles everything.

---

## Step-by-Step Manual Guide

### Step 1 — Configure AWS

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)

# Verify
aws sts get-caller-identity
```

### Step 2 — Set Environment Variables

```bash
cp .env.example .env
# Edit .env:
#   AWS_REGION=us-east-1
#   PROJECT_NAME=eks-mcp
#   EKS_CLUSTER_NAME=eks-mcp-cluster
#   CLOUDWATCH_ALARM_EMAIL=your@email.com
```

### Step 3 — Check Prerequisites

```bash
./scripts/00-check-prerequisites.sh
```

### Step 4 — Bootstrap Terraform Remote State

```bash
./scripts/01-bootstrap-remote-state.sh
# Then uncomment the backend block in infrastructure/environments/dev/provider.tf
```

### Step 5 — Deploy AWS Infrastructure (Terraform)

```bash
./scripts/02-deploy-infrastructure.sh
# This creates: VPC, EKS cluster, GuardDuty detector, CloudWatch log groups + alarms
# Takes ~15-20 minutes
```

After this step your kubeconfig is auto-updated. Verify:
```bash
kubectl get nodes
```

### Step 6 — Setup IRSA for MCP Server

```bash
./scripts/05-setup-mcp-irsa.sh
# Creates IAM role with least-privilege policy for EKS, CloudWatch, GuardDuty read access
```

### Step 7 — Build & Push MCP Server Docker Image

```bash
./scripts/03-build-push-mcp-server.sh
# Builds Python MCP server image and pushes to ECR
```

### Step 8 — Deploy Kubernetes Resources

```bash
./scripts/04-deploy-k8s-resources.sh
# Deploys: CloudWatch Container Insights DaemonSet + MCP Server pods
```

### Step 9 — Verify Everything

```bash
# Check pods
kubectl get pods -n mcp-system
kubectl get pods -n amazon-cloudwatch

# Check MCP server logs
kubectl logs -l app=mcp-server -n mcp-system

# Port-forward to test locally
kubectl port-forward svc/mcp-server 8080:80 -n mcp-system
```

---

## MCP Tools Reference

### EKS Tools
| Tool | Description |
|------|-------------|
| `eks_list_clusters` | Lists all EKS clusters in the region |
| `eks_describe_cluster` | Full cluster details including status and version |
| `eks_list_nodegroups` | Lists node groups for a cluster |
| `eks_get_cluster_health` | Returns health issues if any |

### GuardDuty Tools
| Tool | Description |
|------|-------------|
| `gd_list_detectors` | Lists all GuardDuty detectors |
| `gd_list_findings` | Lists findings filtered by min severity |
| `gd_get_finding_detail` | Full details of a specific finding |
| `gd_finding_summary` | Count of findings by severity bucket |

### CloudWatch Tools
| Tool | Description |
|------|-------------|
| `cw_list_alarms` | Lists alarms filtered by state (OK/ALARM) |
| `cw_query_logs` | Runs Logs Insights queries |
| `cw_get_metric` | Fetches metric statistics |
| `cw_list_log_groups` | Lists available log groups |

---

## Connect to Claude Desktop (or any MCP client)

Add to your `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "eks-guardian": {
      "command": "python3",
      "args": ["/path/to/Eks-GuardDuty/mcp-server/server.py"],
      "env": {
        "AWS_REGION": "us-east-1",
        "AWS_PROFILE": "default"
      }
    }
  }
}
```

---

## Teardown

```bash
./scripts/teardown.sh
# Type 'destroy' to confirm
# Removes: k8s resources → Terraform infra → ECR repo
```

---

## Project Structure

```
Eks-GuardDuty/
├── .env.example                        # Environment variables template
├── .gitignore
├── infrastructure/
│   ├── mcp-server-policy.json          # IAM policy for MCP server IRSA
│   ├── environments/
│   │   └── dev/
│   │       ├── main.tf                 # Root module composition
│   │       ├── provider.tf             # AWS/K8s/Helm providers + backend
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars        # Your values go here
│   └── modules/
│       ├── vpc/                        # VPC with public/private subnets
│       ├── eks/                        # EKS cluster + managed node groups
│       ├── guardduty/                  # GuardDuty detector + SNS + EventBridge
│       └── cloudwatch/                 # Log groups + dashboard + alarms
├── mcp-server/
│   ├── server.py                       # MCP server entrypoint
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── tools/
│   │   ├── eks_tools.py
│   │   ├── guardduty_tools.py
│   │   └── cloudwatch_tools.py
│   └── utils/
│       └── aws_client.py
├── k8s/
│   ├── mcp-server.yaml                 # Deployment + Service + ConfigMap
│   └── cloudwatch-agent.yaml           # Namespace + ServiceAccount
└── scripts/
    ├── deploy-all.sh                   # MASTER: full end-to-end deploy
    ├── 00-check-prerequisites.sh
    ├── 01-bootstrap-remote-state.sh
    ├── 02-deploy-infrastructure.sh
    ├── 03-build-push-mcp-server.sh
    ├── 04-deploy-k8s-resources.sh
    ├── 05-setup-mcp-irsa.sh
    └── teardown.sh
```

---

## Estimated AWS Costs (us-east-1, dev profile)

| Resource | Est. Monthly Cost |
|----------|-------------------|
| EKS Cluster control plane | ~$73 |
| 2x t3.medium nodes | ~$60 |
| NAT Gateway | ~$32 |
| GuardDuty (30 days) | ~$5–30 |
| CloudWatch Logs (light) | ~$5 |
| ECR storage | ~$1 |
| **Total** | **~$175–200/mo** |

> Stop nodes when not in use: `aws eks update-nodegroup-config --cluster-name eks-mcp-cluster --nodegroup-name eks-mcp-cluster-ng --scaling-config minSize=0,maxSize=4,desiredSize=0`
