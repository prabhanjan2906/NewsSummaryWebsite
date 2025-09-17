module "lambda" {
  source       = "./newsapi_fetcher_lambda"
  NEWS_API_KEY = var.NEWS_API_KEY
  COUNTRY      = var.COUNTRY
  LANGUAGE     = var.LANGUAGE
}

output "lambda_datasource_arn" {
  value = module.lambda.lambda_function_arn
}

output "lambda_function_ds" {
  value = module.lambda.headlines_lambda_function_name
}

output "lambda_function_invalid" {
  value = module.lambda.headlines_lambda_function_name_invalid
}
output "lambda_datasource_arn_invalid" {
  value = module.lambda.lambda_function_arn_invalid
}