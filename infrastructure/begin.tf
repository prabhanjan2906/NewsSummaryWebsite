module "NewsIngestor" {
  source               = "./NewsIngestor"
  region               = var.REGION
  newsapi_api_key      = var.NEWS_API_KEY
  language             = var.LANGUAGE
  country              = var.COUNTRY
  env                  = var.ENVIRONMENT
  RAW_BUCKET_INPUT_KEY = var.RAW_BUCKET_INPUT_KEY
  RAW_BUCKET           = var.RAW_BUCKET
}

module "CleanerAndNormalizer" {
  source = "./CleanerAndNormalizer"
  input_sqs_raw_queue_arn = module.NewsIngestor.raw_articles_sqs_queue_arn
  raw_articles_bucket_name = var.RAW_BUCKET
  raw_articles_bucket_url = module.NewsIngestor.raw_articles_bucket_url
  region = var.REGION
  env = var.ENVIRONMENT
  db_name = var.DB_NAME
  db_password = var.DB_PASSWORD
  db_user = var.DB_USER
}