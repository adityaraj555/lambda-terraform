import json
import os
from typing import Any, Dict

import boto3
import botocore.exceptions
from common_utils.error_utils import ErrorCatalog
from common_utils.exceptions import handle_exception
from loguru import logger


def lambda_handler(event: Any, context: Dict):
    """Lambda Handler to invoke Step Function Workflow

    Args:
        event (Dict): It is a JSON-formatted document that contains data
            for a Lambda function to process.
        context (Dict): This object provides methods and properties that
            provide information about the invocation, function,
            and execution environment.

    Returns:
        Dict: Returns the status of invocation
    """
    #setup the batch client
    batch_client = boto3.client(
        "batch", region_name=os.getenv("AWS_REGION", default="us-east-2")
    )
    jobname  = os.environ['jobName']
    jobqueue = os.environ['JobQueue']
    jobdefinition = os.environ['JobDefinition']

    logger.info(f"Recieved Event Message : {json.dumps(event, indent=2)}")

    for message in event["Records"]:
        if message is not None:
            logger.info(f"Received SQS message: {message}")
            payload = json.loads(message["body"])
            job_id = payload.get("jobId", None)
            latitude = payload.get("latitude", None)
            longitude = payload.get("longitude", None)

            if None in [job_id, latitude, longitude]:
                logger.error("Required keys not present in Input")
                handle_exception(ErrorCatalog.RequiredKeyNotInInput.value)

            try:
                #submit the job
                batch_response = batch_client.submit_job(
                    jobName=jobName,
                    jobQueue=jobqueue
                    jobDefinition=jobdefinition
                )
                logger.debug(f"Response from start execution request: {batch_response}")

                job_id = batch_response.get['jobId']
                #resp = batch_client.describe_jobs(jobs=[job_id])

                return {
                    "status": "success",
                    "job_id": job_id,
                    "msg": "Successfully trigerred Step Function",
                    "status_code": "200",
                }

            except botocore.exceptions.ClientError:
                handle_exception(ErrorCatalog.CouldNotConnectToAWS.value)
            except Exception as e:
                logger.error("Exception occured", e)
