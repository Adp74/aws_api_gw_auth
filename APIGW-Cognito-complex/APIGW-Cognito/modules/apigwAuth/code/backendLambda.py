import boto3
import sys
import os
import json
import pprint

        
def handler(event, context):
    # TODO implement
    print("EVENT\n")
    print(event)
    body = event['body'] 
            
    return {
        "statusCode": 200,
        "body": "PoC Backend lambda function",
        "headers": {
            "Content-Type": "application/json"
        }
    }
