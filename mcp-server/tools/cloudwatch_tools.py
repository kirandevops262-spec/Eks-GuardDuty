# mcp-server/tools/cloudwatch_tools.py

from mcp.server import Server
from mcp.types import Tool, TextContent
from utils.aws_client import get_client
import json
import time


def register_cloudwatch_tools(server: Server):

    @server.list_tools()
    async def list_tools():
        return [
            Tool(name="cw_list_alarms",      description="List CloudWatch alarms and their states",             inputSchema={"type": "object", "properties": {"state": {"type": "string", "enum": ["OK", "ALARM", "INSUFFICIENT_DATA"]}}}),
            Tool(name="cw_query_logs",       description="Run a CloudWatch Logs Insights query",                inputSchema={"type": "object", "properties": {"log_group": {"type": "string"}, "query": {"type": "string"}, "minutes": {"type": "integer", "default": 30}}, "required": ["log_group", "query"]}),
            Tool(name="cw_get_metric",       description="Get CloudWatch metric statistics",                    inputSchema={"type": "object", "properties": {"namespace": {"type": "string"}, "metric_name": {"type": "string"}, "dimensions": {"type": "object"}, "minutes": {"type": "integer", "default": 60}}, "required": ["namespace", "metric_name", "dimensions"]}),
            Tool(name="cw_list_log_groups",  description="List available CloudWatch log groups",                inputSchema={"type": "object", "properties": {"prefix": {"type": "string"}}}),
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        cw      = get_client("cloudwatch")
        logs    = get_client("logs")

        if name == "cw_list_alarms":
            kwargs = {}
            if "state" in arguments:
                kwargs["StateValue"] = arguments["state"]
            alarms = cw.describe_alarms(**kwargs)["MetricAlarms"]
            result = [{"name": a["AlarmName"], "state": a["StateValue"], "reason": a.get("StateReason", "")} for a in alarms]
            return [TextContent(type="text", text=json.dumps(result, indent=2))]

        elif name == "cw_query_logs":
            now     = int(time.time())
            minutes = arguments.get("minutes", 30)
            resp    = logs.start_query(
                logGroupName=arguments["log_group"],
                startTime=now - minutes * 60,
                endTime=now,
                queryString=arguments["query"],
            )
            query_id = resp["queryId"]
            # Poll for results
            for _ in range(20):
                time.sleep(1)
                status = logs.get_query_results(queryId=query_id)
                if status["status"] in ("Complete", "Failed", "Cancelled"):
                    break
            rows = [[f["value"] for f in row] for row in status.get("results", [])]
            return [TextContent(type="text", text=json.dumps(rows[:50], indent=2))]

        elif name == "cw_get_metric":
            from datetime import datetime, timedelta
            minutes = arguments.get("minutes", 60)
            dims    = [{"Name": k, "Value": v} for k, v in arguments["dimensions"].items()]
            result  = cw.get_metric_statistics(
                Namespace=arguments["namespace"],
                MetricName=arguments["metric_name"],
                Dimensions=dims,
                StartTime=datetime.utcnow() - timedelta(minutes=minutes),
                EndTime=datetime.utcnow(),
                Period=300,
                Statistics=["Average", "Maximum"],
            )
            points = sorted(result["Datapoints"], key=lambda x: x["Timestamp"])
            return [TextContent(type="text", text=json.dumps([{"time": str(p["Timestamp"]), "avg": p["Average"], "max": p["Maximum"]} for p in points], indent=2))]

        elif name == "cw_list_log_groups":
            kwargs = {}
            if "prefix" in arguments:
                kwargs["logGroupNamePrefix"] = arguments["prefix"]
            groups = logs.describe_log_groups(**kwargs)["logGroups"]
            return [TextContent(type="text", text=json.dumps([g["logGroupName"] for g in groups], indent=2))]

        return [TextContent(type="text", text=f"Unknown tool: {name}")]
