import os, sys
import config

def setup_s3_client():
    pth = os.path.join(os.path.dirname(__file__), 'package')
    if pth not in sys.path:
        sys.path.insert(0, pth)
    import boto3
    return boto3.client("s3", region_name=config.get_region())

def s3_client_config(func):
    s3_client = setup_s3_client()
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    wrapper.s3_client = s3_client
    return wrapper
