import os, sys, uuid

app_config = {
    "region" : os.environ.get("AWS_REGION"),
    "input_prefix" : os.environ.get("INPUT_PREFIX"),
    # "key" : 'raw/'
    "output_prefix" : str(os.environ.get("OUTPUT_PREFIX")) + "/"
}

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

def config(func):
    bedrock_client = setup_bedrock_client()
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    wrapper.bedrock_client = bedrock_client
    return wrapper
