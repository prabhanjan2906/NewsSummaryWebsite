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