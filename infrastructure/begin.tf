module "lambda" {
  source       = "./newsapi_fetcher_lambda"
  NEWS_API_KEY = var.NEWS_API_KEY
  COUNTRY      = var.COUNTRY
  LANGUAGE     = var.LANGUAGE
}