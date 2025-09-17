module "lambda" {
  source       = "./newsapi_fetcher_lambda"
  NEWS_API_KEY = var.NEWS_API_KEY
  COUNTRY      = var.COUNTRY
  LANGUAGE     = var.LANGUAGE
}

output "lambda_function_name" {
  value = module.lambda.lambda_function_name
}

output "lambda_datasource_arn" {
  value = module.lambda.lambda_datasource_arn
}

output "lambda_function_ds" {
  value = module.lambda.headlines_lambda_function_name
}