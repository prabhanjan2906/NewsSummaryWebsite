locals {
  bucket_name                            = "${var.env}-${var.raw_bucket_name}"
  pythonVersion                          = "python3.14"
  newsapi_headline_ingestion_lambda_name = "${var.env}-newsapi_headline_ingestion"
  lambda_schedule_rate                   = "rate(1 hour)"
}