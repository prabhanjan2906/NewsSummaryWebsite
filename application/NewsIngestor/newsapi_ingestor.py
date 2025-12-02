import os
import json
import uuid
from datetime import datetime, timezone

import boto3

s3_client = boto3.client("s3")
sqs_client = boto3.client("sqs")

RAW_BUCKET_NAME = os.environ["RAW_BUCKET_NAME"]
RAW_ARTICLES_QUEUE_URL = os.environ["RAW_ARTICLES_QUEUE_URL"]
SOURCE_ID = os.environ.get("SOURCE_ID", "newsapi")
RAW_BUCKET_PREFIX_KEY = os.environ.get("PREFIX_KEY", "raw")

# NEWSAPI_API_KEY = os.environ["NEWSAPI_API_KEY"]
# NEWSAPI_ENDPOINT = os.environ.get("NEWSAPI_ENDPOINT", "https://newsapi.org/v2/top-headlines")
NEWSAPI_COUNTRY = os.environ.get("NEWSAPI_COUNTRY", "us")
NEWSAPI_LANGUAGE = os.environ.get("NEWSAPI_LANGUAGE", "en")
NEWSAPI_CATEGORY = os.environ.get("NEWSAPI_CATEGORY", "")

# # pip install custom package to /tmp/ and add to path
import sys
import subprocess

subprocess.call('pip install -r requirements.txt -t /tmp/ --no-cache-dir'.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
sys.path.insert(0, '/tmp/')

import newsHeadlinesFetcher
import webscraper

# client = news_api_client.NewsApiClientExtended()
output_message_queue = os.getenv('NEWSAPI_OUTPUT_QUEUE_URL', None)

def build_s3_key(source: str, now_utc: datetime, article_uuid: str) -> str:
    """Return S3 key in the form: raw/yyyy/mm/dd/source_uuid.json"""
    yyyy = now_utc.year
    mm = now_utc.month
    dd = now_utc.day
    return f"{RAW_BUCKET_PREFIX_KEY}/{yyyy:04d}/{mm:02d}/{dd:02d}/{source}_{article_uuid}.json"


def call_newsapi() -> list[dict]:
    # """
    # Call NewsAPI 'top-headlines' endpoint and return the list of articles.
    # NOTE: This is a simple example and does not handle pagination, sources, etc.
    # """
    # params = {
    #     "apiKey": NEWSAPI_API_KEY,
    #     "country": NEWSAPI_COUNTRY
    # }
    # # Add category only if provided
    # if NEWSAPI_CATEGORY:
    #     params["category"] = NEWSAPI_CATEGORY

    # resp = requests.get(NEWSAPI_ENDPOINT, params=params, timeout=10)
    # resp.raise_for_status()
    # data = resp.json()

    # # NewsAPI returns: { "status": "...", "totalResults": n, "articles": [ ... ] }
    # return data.get("articles", [])

    return newsHeadlinesFetcher.getNews()
        # sqs_client = boto3.client('sqs')

    #     for anObj in data:
    #         sqs_client.send_message(
    #             QueueUrl=output_message_queue,
    #             MessageBody=json.dumps(anObj)
    #         )
    # return {"statusCode": 200 if data else 417, "body": len(data) if data else 0}



def handler(event, context):
    articles = []

    try:
        articles = call_newsapi()
    except Exception as e:
        # You can improve logging/metrics as needed
        print(f"Error calling NewsAPI: {e}")
        raise

    print(f"Fetched {len(articles)} articles from NewsAPI")

    for article in articles:
        process_article(article)

    return {
        "statusCode": 200,
        "body": json.dumps({"message": f"Ingested {len(articles)} articles from NewsAPI"})
    }


def process_article(article: dict) -> None:
    """
    For one NewsAPI article:
    - generate a UUID
    - build S3 key
    - build envelope JSON and write to S3
    - send SQS message with metadata
    """

    article_uuid = str(uuid.uuid4())  # Random UUID for this article
    now_utc = datetime.now(timezone.utc)

    # Basic fields from NewsAPI
    url = article.get("url")
    title = article.get("title")
    author = article.get("author")
    description = webscraper.fetchWebpageArticle(url)
    if not description:
        return

    # publishedAt from NewsAPI may be ISO format; we'll preserve as-is if present
    published_at_raw = article.get("publishedAt")
    published_at_iso = None
    if published_at_raw:
        # A safe way is to just trust the ISO string for now
        published_at_iso = published_at_raw
    else:
        # Fallback: if missing, we use current ingestion time
        published_at_iso = now_utc.isoformat()

    language = article.get("language", "en")  # NewsAPI doesn't always return this; keep default
    # external_id – NewsAPI doesn't give a strict ID; we can leave this null or derive a hash
    external_id = None

    # Build S3 key
    s3_key = build_s3_key(SOURCE_ID, now_utc, article_uuid)

    # Build envelope JSON for S3
    envelope = {
        "source": SOURCE_ID,
        "external_id": external_id,
        "url": url,
        "fetched_at": now_utc.isoformat(),
        "published_at": published_at_iso,
        "language": language,
        "title": title,
        "raw_html": None,  # NewsAPI only gives JSON; no HTML
        "raw_text": description,  # or combine title + description if you want
        "metadata": {
            "author": author,
            "source_payload": article
        },
        "article_uuid": article_uuid
    }

    # Write to S3
    put_raw_article_to_s3(s3_key, envelope)

    # Send message to SQS
    send_raw_article_message_to_sqs(
        source=SOURCE_ID,
        s3_key=s3_key,
        url=url,
        external_id=external_id,
        published_at=published_at_iso,
        language=language
    )


def put_raw_article_to_s3(s3_key: str, envelope: dict) -> None:
    body = json.dumps(envelope).encode("utf-8")
    try:
        s3_client.put_object(
            Bucket=RAW_BUCKET_NAME,
            Key=s3_key,
            Body=body,
            ContentType="application/json"
        )
        print(f"Stored raw article in s3://{RAW_BUCKET_NAME}/{s3_key}")
    except Exception as e:
        print(f"Error writing to S3 for key {s3_key}: {e}")
        # Depending on your preference, you can raise here to fail the batch
        # how to put it to DLQ?


def send_raw_article_message_to_sqs(
    source: str,
    s3_key: str,
    url: str,
    external_id: str | None,
    published_at: str,
    language: str
) -> None:
    message_body = {
        "version": 1,
        "source": source,
        "s3_key": s3_key,
        "url": url,
        "external_id": external_id,
        "published_at": published_at,
        "language": language
    }

    try:
        resp = sqs_client.send_message(
            QueueUrl=RAW_ARTICLES_QUEUE_URL,
            MessageBody=json.dumps(message_body)
        )
        print(f"Sent message to SQS with MessageId={resp.get('MessageId')}")
    except Exception as e:
        print(f"Error sending SQS message for s3_key {s3_key}: {e}")
        # Again, decide if you want to raise to fail the batch
        #raise # put it to DLQ?
