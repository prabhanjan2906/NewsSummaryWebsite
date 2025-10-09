import os, sys, uuid

app_config = {
    "region" : os.environ.get("AWS_REGION"),
    "model_id" : os.environ.get("MODEL_ID"),
    "input_prefix" : os.environ.get("INPUT_PREFIX"),
    # "key" : 'raw/'
    "output_prefix" : str(os.environ.get("OUTPUT_PREFIX")) + "/"
}

def get_region():
    return app_config.get('region')

def get_input_prefix():
    return app_config.get("input_prefix")

def get_output_prefix():
    return app_config.get("output_prefix")

def get_unique_key():
    return app_config.get("input_prefix") + f"{uuid.uuid4()}.json"

def setup_bedrock_client():
    pth = os.path.join(os.path.dirname(__file__), 'package')
    if pth not in sys.path:
        sys.path.insert(0, pth)
    import boto3
    return boto3.client("bedrock-runtime", region_name=app_config.get('region'))

def setup_s3_client():
    pth = os.path.join(os.path.dirname(__file__), 'package')
    if pth not in sys.path:
        sys.path.insert(0, pth)
    import boto3
    return boto3.client("s3", region_name=app_config.get('region'))

def bedrock_client_config(func):
    bedrock_client = setup_bedrock_client()
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    wrapper.bedrock_client = bedrock_client
    return wrapper

def s3_client_config(func):
    s3_client = setup_s3_client()
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    wrapper.s3_client = s3_client
    return wrapper
