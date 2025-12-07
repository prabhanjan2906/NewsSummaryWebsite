import os
import json
from datetime import datetime
from typing import Optional

import boto3
import psycopg2
import psycopg2.extras

# ---- AWS clients ----
s3_client = boto3.client("s3")
sqs_client = boto3.client("sqs")

RAW_BUCKET_NAME = os.environ["RAW_BUCKET_NAME"]
RAW_ARTICLES_QUEUE_URL = os.environ["RAW_ARTICLES_QUEUE_URL"]
ARTICLE_READY_FOR_CLUSTERING_QUEUE_URL = os.environ["ARTICLE_READY_FOR_CLUSTERING_QUEUE_URL"]
import db_helper

def handler(event, context):
    """
    SQS-triggered handler. 'event' contains Records -> messages from raw-articles-queue.
    For each message:
      - parse JSON
      - read S3 object
      - dedupe + insert into 'articles'
      - emit to 'article-ready-for-clustering-queue'
    """
    records = event.get("Records", [])
    print(f"Received {len(records)} SQS records")

    conn = db_helper.get_db_connection()
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    failures = []
    for record in records:
        try:
            process_sqs_record(record, cursor)

            # commit once for the whole batch
            conn.commit()
        except Exception as e:
            msg_id = record["messageId"]
            failures.append({"itemIdentifier": msg_id})
            conn.rollback()
            print(f"Error processing batch, rolled back transaction: {e}")
            # raise to let Lambda/SQS retry
            raise
    db_helper.closeDB()

    return {"batchItemFailures": failures}


def process_sqs_record(record, cursor):
    body = record["body"]
    try:
        msg = json.loads(body)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in message body: {e} | body={body}")
        # We can choose to swallow or raise; here we log and skip.
        return

    version = msg.get("version")
    if version != 1:
        print(f"Unsupported message version: {version}")
        return

    source = msg.get("source")
    s3_key = msg.get("s3_key")
    url = msg.get("url")
    external_id = msg.get("external_id")
    published_at_iso = msg.get("published_at")
    language = msg.get("language")

    if not s3_key or not url:
        print(f"Missing required fields in message: {msg}")
        return

    # Load raw envelope from S3
    envelope = load_raw_envelope_from_s3(s3_key)

    # Basic dedupe check
    existing_article_id = find_existing_article(cursor, url, source, external_id)
    
    if existing_article_id is not None:
        print(f"Duplicate article detected (url={url}); id={existing_article_id}")
        # Optionally delete S3 object to avoid orphaned raw files
        # If you want to keep all raw ingestion payloads, comment this out.
        try:
            s3_client.delete_object(Bucket=RAW_BUCKET_NAME, Key=s3_key)
            print(f"Deleted duplicate raw object s3://{RAW_BUCKET_NAME}/{s3_key}")
        except Exception as e:
            print(f"Failed to delete duplicate raw object: {e}")
        return

    # Insert new article into DB
    article_id = insert_article(
        cursor=cursor,
        source=source,
        external_id=external_id,
        url=url,
        published_at_iso=published_at_iso,
        language=language,
        raw_text_location=s3_key,
        envelope=envelope,
    )

    print(f"Inserted new article id={article_id} (url={url})")

    # Send message to next stage (article-ready-for-clustering-queue)
    send_article_ready_message(article_id, source, published_at_iso, language)


def load_raw_envelope_from_s3(s3_key: str) -> dict:
    try:
        resp = s3_client.get_object(Bucket=RAW_BUCKET_NAME, Key=s3_key)
        data = resp["Body"].read()
        envelope = json.loads(data)
        return envelope
    except Exception as e:
        print(f"Error loading raw envelope from s3://{RAW_BUCKET_NAME}/{s3_key}: {e}")
        raise


def find_existing_article(
    cursor,
    url: str,
    source: Optional[str],
    external_id: Optional[str],
) -> Optional[int]:
    """
    Check if an article already exists based on:
      - exact url match, OR
      - (source, external_id) match if external_id is not null.

    Returns article id if found, else None.
    """
    # First, check by URL
    cursor.execute("SELECT id FROM articles WHERE url = %s", (url,))
    row = cursor.fetchone()
    if row:
        return row["id"]

    # Optionally check by (source, external_id) if external_id is present
    if source and external_id:
        cursor.execute(
            "SELECT id FROM articles WHERE source = %s AND external_id = %s",
            (source, external_id),
        )
        row = cursor.fetchone()
        if row:
            return row["id"]

    return None


def insert_article(
    cursor,
    source: str,
    external_id: Optional[str],
    url: str,
    published_at_iso: Optional[str],
    language: Optional[str],
    raw_text_location: str,
    envelope: dict,
) -> int:
    """
    Insert a new row into 'articles' and return the article_id.
    We use fields defined in our blueprint.
    """
    title = envelope.get("title")
    # If the envelope stored a raw_text, we can keep that for convenience, but
    # the true cleaning may happen in a later stage if desired.
    # For now we won't store raw_text in the articles table (only raw_text_location).
    published_at = None
    if published_at_iso:
        try:
            published_at = datetime.fromisoformat(published_at_iso.replace("Z", "+00:00"))
        except Exception:
            # fallback: treat as text string and let DB cast if column is timestamptz
            published_at = published_at_iso

    created_at = datetime.utcnow()

    # Insert and return id
    cursor.execute(
        """
        INSERT INTO articles
          (source, external_id, url, title, published_at, language,
           cluster_id, raw_text_location, created_at)
        VALUES (%s, %s, %s, %s, %s, %s,
                NULL, %s, %s)
        RETURNING id
        """,
        (
            source,
            external_id,
            url,
            title,
            published_at,
            language,
            raw_text_location,
            created_at,
        ),
    )

    row = cursor.fetchone()
    return row["id"]


def send_article_ready_message(
    article_id: int,
    source: str,
    published_at_iso: Optional[str],
    language: Optional[str],
) -> None:
    """
    Send a small message to article-ready-for-clustering-queue to kick off clustering.
    """
    message_body = {
        "version": 1,
        "article_id": article_id,
        "source": source,
        "published_at": published_at_iso,
        "language": language,
    }

    try:
        resp = sqs_client.send_message(
            QueueUrl=ARTICLE_READY_FOR_CLUSTERING_QUEUE_URL,
            MessageBody=json.dumps(message_body),
        )
        print(
            f"Sent article-ready message for article_id={article_id}, "
            f"MessageId={resp.get('MessageId')}"
        )
    except Exception as e:
        print(f"Error sending article-ready message for article_id={article_id}: {e}")
        # Depending on how strict you want to be, you could raise here to retry the batch
        raise
