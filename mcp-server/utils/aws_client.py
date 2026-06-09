# mcp-server/utils/aws_client.py

import boto3
import os
from functools import lru_cache

REGION = os.getenv("AWS_REGION", "us-east-1")

@lru_cache(maxsize=None)
def get_client(service: str):
    return boto3.client(service, region_name=REGION)
