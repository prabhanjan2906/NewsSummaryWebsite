import s3_config
import json

@s3_config.s3_client_config
def read_from_s3(bucket, key):
    obj = read_from_s3.s3_client.get_object(Bucket=bucket, Key=key)
    return obj["Body"].read().decode("utf-8")

@s3_config.s3_client_config
def write_to_s3(bucket, key, jsondata):
    obj = write_to_s3.s3_client.put_object(Bucket=bucket, Key=key, Body=json.dumps(jsondata))
    return obj["Body"].read().decode("utf-8")
