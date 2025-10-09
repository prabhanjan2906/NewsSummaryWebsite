import os, sys, config

def setup_bedrock_client():
    pth = os.path.join(os.path.dirname(__file__), 'package')
    if pth not in sys.path:
        sys.path.insert(0, pth)
    import boto3
    return boto3.client("bedrock-runtime", region_name=config.get_region())

def bedrock_client_config(func):
    bedrock_client = setup_bedrock_client()
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    wrapper.bedrock_client = bedrock_client
    return wrapper

def get_model_id():
    return config.app_config.get('model_id')
