import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'package'))

import newsHeadlinesFetcher

def handler(event, context):
    data = newsHeadlinesFetcher.getNews()
    payload = data['articles'] if data else []
    return {"statusCode": 200 if data else 417, "body": payload}
