#just testing very_simple python script
import json
import boto3

print("successfully executed BATCH JOB")

def lambda_handler(event, context):
    
 
    return {
        'statusCode': 200,
        'body': json.dumps('SUCCESSFULL')
    }


