module "lambda" {
  source       = "./newsapi_fetcher_lambda"
  NEWS_API_KEY = var.NEWS_API_KEY
  COUNTRY      = var.COUNTRY
  LANGUAGE     = var.LANGUAGE
}

output "newsapi_arn" {
  value = module.lambda.newsapi_fetcher_lambda_function_arn
}