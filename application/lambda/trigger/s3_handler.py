import s3_config

@s3_config.s3_client_config
def read_from_s3(bucket, key):
    obj = read_from_s3.s3_client.get_object(Bucket=bucket, Key=key)
    return obj["Body"].read().decode("utf-8")