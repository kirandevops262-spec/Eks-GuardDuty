# mcp-server/tools/guardduty_tools.py

from mcp.server import Server
from mcp.types import Tool, TextContent
from utils.aws_client import get_client
import json


def register_guardduty_tools(server: Server):

    @server.list_tools()
    async def list_tools():
        return [
            Tool(name="gd_list_detectors",     description="List all GuardDuty detectors",                        inputSchema={"type": "object", "properties": {}}),
            Tool(name="gd_list_findings",       description="List GuardDuty findings (optionally filter severity)", inputSchema={"type": "object", "properties": {"detector_id": {"type": "string"}, "min_severity": {"type": "number", "default": 4}}, "required": ["detector_id"]}),
            Tool(name="gd_get_finding_detail",  description="Get full detail of a specific GuardDuty finding",     inputSchema={"type": "object", "properties": {"detector_id": {"type": "string"}, "finding_id": {"type": "string"}}, "required": ["detector_id", "finding_id"]}),
            Tool(name="gd_finding_summary",     description="Summarized count of findings by severity",            inputSchema={"type": "object", "properties": {"detector_id": {"type": "string"}}, "required": ["detector_id"]}),
        ]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict):
        gd = get_client("guardduty")

        if name == "gd_list_detectors":
            result = gd.list_detectors()
            return [TextContent(type="text", text=json.dumps(result["DetectorIds"], indent=2))]

        elif name == "gd_list_findings":
            detector_id  = arguments["detector_id"]
            min_severity = float(arguments.get("min_severity", 4))
            finding_ids  = gd.list_findings(
                DetectorId=detector_id,
                FindingCriteria={"Criterion": {"severity": {"Gte": min_severity}}}
            )["FindingIds"]
            return [TextContent(type="text", text=json.dumps({"count": len(finding_ids), "finding_ids": finding_ids[:20]}, indent=2))]

        elif name == "gd_get_finding_detail":
            findings = gd.get_findings(
                DetectorId=arguments["detector_id"],
                FindingIds=[arguments["finding_id"]]
            )["Findings"]
            f = findings[0] if findings else {}
            summary = {
                "id":          f.get("Id"),
                "type":        f.get("Type"),
                "severity":    f.get("Severity"),
                "title":       f.get("Title"),
                "description": f.get("Description"),
                "region":      f.get("Region"),
                "createdAt":   f.get("CreatedAt"),
                "resource":    f.get("Resource", {}).get("ResourceType"),
            }
            return [TextContent(type="text", text=json.dumps(summary, indent=2))]

        elif name == "gd_finding_summary":
            detector_id = arguments["detector_id"]
            counts = {}
            for label, threshold in [("HIGH", 7), ("MEDIUM", 4), ("LOW", 1)]:
                ids = gd.list_findings(
                    DetectorId=detector_id,
                    FindingCriteria={"Criterion": {"severity": {"Gte": threshold}}}
                )["FindingIds"]
                counts[label] = len(ids)
            counts["MEDIUM"] -= counts["HIGH"]
            return [TextContent(type="text", text=json.dumps(counts, indent=2))]

        return [TextContent(type="text", text=f"Unknown tool: {name}")]
