#just testing simple_batch_job  python script

import json
import boto3

print("successfully connected SIMPLE_BATCH_JOB")

def lambda_handler(event, context):
    
 
    return {
        'statusCode': 200,
        'body': json.dumps('SUCCESSFULL')
    }


