module "lambda" {
  source       = "./newsapi_fetcher_lambda"
  NEWS_API_KEY = var.NEWS_API_KEY
  COUNTRY      = var.COUNTRY
  LANGUAGE     = var.LANGUAGE
}

module "consumer" {
  source                    = "./consumer"
  newsapi_message_queue_arn = module.lambda.newsapi_message_queue_arn
  RAW_BUCKET                = var.RAW_BUCKET
}

output "newsapi_arn" {
  value = module.lambda.newsapi_fetcher_lambda_function_arn
}