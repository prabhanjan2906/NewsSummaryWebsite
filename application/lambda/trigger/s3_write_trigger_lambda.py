import urllib
import config
import s3_handler
import news_article_processor

def handler(event, context):
    print(event)
    print(context)
    for rec in event.get("Records", []):
        bucket = rec["s3"]["bucket"]["name"]
        key    = urllib.parse.unquote_plus(rec["s3"]["object"]["key"])

        # Ignore non-input paths to avoid loops
        if not key.startswith(config.get_input_prefix()):
            continue

        # Read input JSON (as text)
        payload = s3_handler.read_from_s3(bucket, key)

        news_article_processor.generate_summary_and_topics(payload)
        # output_text = "".join(p["text"] for p in out["output"]["message"]["content"])

        # # Write to processed/ with same file name after the prefix
        # tail = key[len(config.get_input_prefix()):]
        # out_key = f"{config.get_output_prefix()}{tail}"
        # _write_text(bucket, out_key, output_text)

    return {"ok": True}