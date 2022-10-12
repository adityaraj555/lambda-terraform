import json
import os
from typing import Any, Dict

import boto3
import botocore.exceptions
from common_utils.error_utils import ErrorCatalog
from common_utils.exceptions import handle_exception
from loguru import logger


def lambda_handler(event: Any, context: Dict):
    """Lambda Handler to notify result to response queue

    Args:
        event (Dict): It is a JSON-formatted document that contains data
            for a Lambda function to process.
        context (Dict): This object provides methods and properties that
            provide information about the invocation, function, and
            execution environment.

    Returns:
        Dict: Returns the status of invocation
    """

    sqs_client = boto3.client("sqs", region_name=os.getenv("AWS_REGION", default="us-east-2"))
    logger.info(f"Recieved Event Message : {json.dumps(event, indent=2)}")
    job_id = event.get("jobId", None)
    internal_response_queue_url = os.getenv(
        "internal_response_queue_url", "app-sandbox-1x0-sqs-simple-lambda-test-response-queue"
    )
    state = event.get("state", None)
    info = event.get("info", None)
    error_cause = event.get("Cause", None)
    if None in [job_id, state]:
        logger.error("Required keys not present in Input")
        handle_exception(ErrorCatalog.RequiredKeyNotInInput.value)

    try:
        message_body = dict()
        message_body["jobId"] = job_id
        message_body["status"] = state
        response = dict()
        if info is not None:
            response["output"] = info
        message_body["response"] = response

        if error_cause is not None and "error_message" in error_cause:
            error_cause = json.loads(error_cause)
            message_body["message"] = error_cause["error_message"]

        sqs_response = sqs_client.send_message(
            QueueUrl=internal_response_queue_url, MessageBody=json.dumps(message_body)
        )
        logger.debug(f"Response from internal SQS queue: {sqs_response}")

        return {
            "status": "success",
            "jobId": job_id,
            "msg": "Successfully triggered callback" + json.dumps(message_body),
            "status_code": "200",
        }

    except botocore.exceptions.ClientError:
        handle_exception(ErrorCatalog.CouldNotConnectToAWS.value)
