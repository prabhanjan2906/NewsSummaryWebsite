import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'package'))
import webscraper

def handler(event, context):
    webscraper.fetchWebpageArticle(event)
    print(f"Received event: {event}\n")
    print(f"Event Context: \n{context}\n")
    return {
        'statusCode': 200,
        'body': event
    }




# Received event: {
# "key1": "value1",
# "key2": "value2",
# "key3": "value3"
# }

# # Event Context: 
# # LambdaContext(
# [aws_request_id=6e928b3c-b405-4351-b236-24eda09c77d7,
#  log_group_name=/aws/lambda/news_headlines_function,
#  log_stream_name=2025/09/17/[$LATEST]27fad81a5c9541f19c2b086a3733066c,
#  function_name=news_headlines_function,
#  memory_limit_in_mb=128,
#  function_version=$LATEST,
#  invoked_function_arn=arn:aws:lambda:us-east-2:343938549966:function:news_headlines_function,
#  client_context=None,identity=CognitoIdentity([cognito_identity_id=None,cognito_identity_pool_id=None]),tenant_id=None]
# #)
