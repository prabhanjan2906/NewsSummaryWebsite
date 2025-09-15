module "lambda" {
  source       = "./lambda"
  NEWS_API_KEY = var.NEWS_API_KEY
  COUNTRY      = var.COUNTRY
  LANGUAGE     = var.LANGUAGE
}