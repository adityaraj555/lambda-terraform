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
    job_name  = os.environ['job_name']
    job_queues = os.environ['job_queues']
    job_definitions = os.environ['job_definitions']

    print("aws batch triggered successfully")
  
    batch_response = batch_client.submit_job(
        jobName=job_name,
        jobQueue=job_queues,
        jobDefinition=job_definitions
    )
    logger.debug(f"Response from started batch job execution request: {batch_response}")

    #fetching job_id  as  job result
    job_id = batch_response['jobId']
    

    return {
         "status": "success",
         "job_id": job_id,
         "msg": "Successfully trigerred Batch Function",
         "status_code": "200",
    }

    except botocore.exceptions.ClientError:
        handle_exception(ErrorCatalog.CouldNotConnectToAWS.value)
    except Exception as e:
        logger.error("Exception occured", e)
