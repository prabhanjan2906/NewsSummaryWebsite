from logging import log
import json
import config

@config.config
def writeData(jsondata):
    writeData.s3_client.put_object(Bucket=config.get_bucketname(), Key=config.get_unique_key(), Body=json.dumps(jsondata))