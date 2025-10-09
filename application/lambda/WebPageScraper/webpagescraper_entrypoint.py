import os
import sys
import subprocess
from logging import log
import json
import write_to_s3

# pip install custom package to /tmp/ and add to path
subprocess.call('pip install -r requirements.txt -t /tmp/ --no-cache-dir'.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
sys.path.insert(1, '/tmp/')

def installdependencies():
    print("Installing dependencies")
    os.system('pip install trafilatura -t /tmp')

def handler(event, context):
    import webscraper
    failures = []
    for record in event["Records"]:
        msg_id = record["messageId"]
        try:
            body = json.loads(record["body"])
            data = webscraper.fetchWebpageArticle(body)
            if data:
                write_to_s3.writeData(data)
                
        except Exception as e:
            print(f"Failed to process messageId={msg_id}")
            print(f"Failed to process error={e}")
            failures.append({"itemIdentifier": msg_id})
    # Only these IDs will be retried by SQS/Lambda
    return {"batchItemFailures": failures}
