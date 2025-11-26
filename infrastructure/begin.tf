module "lambda" {
  source       = "./newsapi_fetcher_lambda"
  NEWS_API_KEY = var.NEWS_API_KEY
  COUNTRY      = var.COUNTRY
  LANGUAGE     = var.LANGUAGE
}

module "consumer" {
  source = "./consumer"
  # newsapi_message_queue_arn = module.lambda.newsapi_message_queue_arn
  RAW_BUCKET                = var.RAW_BUCKET
  ENVIRONMENT               = var.ENVIRONMENT
  RAW_BUCKET_INPUT_KEY      = var.RAW_BUCKET_INPUT_KEY
  python_version_for_lambda = local.python_version
}

module "s3_write_trigger" {
  source                                   = "./trigger"
  python_dependency_layer_arn              = module.consumer.python_dependency_layer_arn
  raw_data_storage_for_webpage_scraper_id  = module.consumer.raw_data_storage_for_webpage_scraper_id
  raw_data_storage_for_webpage_scraper_arn = module.consumer.raw_data_storage_for_webpage_scraper_arn
  RAW_BUCKET                               = var.RAW_BUCKET
  ENVIRONMENT                              = var.ENVIRONMENT
  REGION                                   = local.region
  python_version_for_lambda                = local.python_version
  RAW_BUCKET_INPUT_KEY                     = var.RAW_BUCKET_INPUT_KEY
  RAW_BUCKET_OUTPUT_KEY                    = var.RAW_BUCKET_OUTPUT_KEY
  MODEL_ID                                 = var.MODEL_ID
}

# output "newsapi_arn" {
#   value = module.lambda.newsapi_fetcher_lambda_function_arn
# }