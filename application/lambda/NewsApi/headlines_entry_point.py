import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'package'))

import newsHeadlinesFetcher

def handler(event, context):
    data = newsHeadlinesFetcher.getNews()
    status_code = 200 if data and data['status'] == 'ok' else 417
    payload = data['articles'] if data else []
    return {"statusCode": status_code, "body": payload}
