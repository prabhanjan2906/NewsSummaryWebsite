import os, sys, uuid

app_config = {
    "region" : os.environ.get("AWS_REGION"),
    "bucket_name" : os.environ.get("RAW_BUCKET"),
    "key" : 'raw/'
}

def get_bucketname():
    return app_config.get("bucket_name")

def get_unique_key():
    return app_config.get("key") + f"{uuid.uuid4()}.json"

def setup_client():
    pth = os.path.join(os.path.dirname(__file__), 'package')
    if pth not in sys.path:
        sys.path.insert(0, pth)
    import boto3
    return boto3.client("s3", region_name=app_config.get('region'))

def config(func):
    s3_client = setup_client()
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    wrapper.s3_client = s3_client
    return wrapper
