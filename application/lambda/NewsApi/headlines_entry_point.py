import os
import sys, boto3, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'package'))

import newsHeadlinesFetcher

output_message_queue = os.getenv('NEWSAPI_OUTPUT_QUEUE_URL', None)

def handler(event, context):
    data = newsHeadlinesFetcher.getNews()
    payload = data['articles'] if data else []
    if output_message_queue and data:
        sqs_client = boto3.client('sqs')

        for anObj in payload:
            sqs_client.send_message(
                QueueUrl=output_message_queue,
                MessageBody=json.dumps(anObj)
            )
    return {"statusCode": 200 if data else 417, "body": len(payload)}