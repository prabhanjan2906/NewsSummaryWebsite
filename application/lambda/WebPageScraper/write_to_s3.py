from logging import log
import os
import sys, json
import boto3
sys.path.append(os.path.join(os.getcwd(), 'package'))

s3 = boto3.client("s3")
RAW_BUCKET = os.environ["RAW_BUCKET"]

def writeData(jsondata):
    pass