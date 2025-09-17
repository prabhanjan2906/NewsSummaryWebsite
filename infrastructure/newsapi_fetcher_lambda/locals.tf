locals {
    environment = "development"
    lambda_function_name = "news_headlines_function"
    lambda_schedule_rate = "rate(1 hour)"
}