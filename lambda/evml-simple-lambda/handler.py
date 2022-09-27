# Copyright Eagleview Private Limited. All Rights Reserved.

# snippet-start:[lambda.evml-simple-lambda]
import asyncio
import json
import os
from typing import Any, Dict

from common_utils.error_utils import ErrorCatalog
from common_utils.exceptions import handle_exception
from loguru import logger

loop = asyncio.get_event_loop()
ENV = os.getenv("ENV", default="sandbox")
max_retries = 5


def lambda_handler(event: Any, context: Dict):
    logger.info(f"Recieved Event Message : {json.dumps(event, indent=2)}")
    lats = event.get("latitude", None)
    lons = event.get("longitude", None)

    if None in [lats, lons]:
        handle_exception(ErrorCatalog.RequiredKeyNotInInput.value)

    logger.info(f"Received request for latitudes : {lats} and longitudes : {lons}")
    return {
            "status": "success",
            "info":  f"Received  message: {lats, lons}",
            "msg": "Successfully retrieved parcel boundary",
            "status_code": "200",
        }
