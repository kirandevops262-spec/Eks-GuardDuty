# mcp-server/tools/eks_tools.py

from mcp.server import Server
from mcp.types import Tool, TextContent
from utils.aws_client import get_client
import json


def register_eks_tools(server: Server):

    @server.list_tools()
    async def list_tools():
        return [
            Tool(name="eks_list_clusters",        description="List all EKS clusters",                  inputSchema={"type": "object", "properties": {}}),
            Tool(name="eks_describe_cluster",      description="Get EKS cluster details",                inputSchema={"type": "object", "properties": {"cluster_name": {"type": "string"}}, "required": ["cluster_name"]}),
            Tool(name="eks_list_nodegroups",       description="List node groups for a cluster",         inputSchema={"type": "object", "properties": {"cluster_name": {"type": "string"}}, "required": ["cluster_name"]}),
            Tool(name="eks_get_cluster_health",    description="Get cluster health status and issues",   inputSchema={"type": "object", "properties": {"cluster_name": {"type": "string"}}, "required": ["cluster_name"]}),
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        eks = get_client("eks")

        if name == "eks_list_clusters":
            result = eks.list_clusters()
            return [TextContent(type="text", text=json.dumps(result["clusters"], indent=2))]

        elif name == "eks_describe_cluster":
            result = eks.describe_cluster(name=arguments["cluster_name"])
            cluster = result["cluster"]
            summary = {
                "name":     cluster["name"],
                "status":   cluster["status"],
                "version":  cluster["version"],
                "endpoint": cluster.get("endpoint", "N/A"),
                "logging":  cluster.get("logging", {}),
            }
            return [TextContent(type="text", text=json.dumps(summary, indent=2))]

        elif name == "eks_list_nodegroups":
            result = eks.list_nodegroups(clusterName=arguments["cluster_name"])
            return [TextContent(type="text", text=json.dumps(result["nodegroups"], indent=2))]

        elif name == "eks_get_cluster_health":
            result = eks.describe_cluster(name=arguments["cluster_name"])
            health = result["cluster"].get("health", {})
            return [TextContent(type="text", text=json.dumps(health, indent=2))]

        return [TextContent(type="text", text=f"Unknown tool: {name}")]
