# mcp-server/server.py
# Main MCP Server — EKS + CloudWatch + GuardDuty

import asyncio
import os
from dotenv import load_dotenv
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

from tools.eks_tools import register_eks_tools
from tools.guardduty_tools import register_guardduty_tools
from tools.cloudwatch_tools import register_cloudwatch_tools

load_dotenv()

server = Server("eks-cloudwatch-guardduty-mcp")

# ── Register all tool groups ──────────────────────────────
register_eks_tools(server)
register_guardduty_tools(server)
register_cloudwatch_tools(server)


@server.list_resources()
async def list_resources():
    return []


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
