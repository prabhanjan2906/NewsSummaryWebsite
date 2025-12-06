############################
# S3 Bucket for raw/      #
############################

resource "aws_s3_bucket" "raw_articles" {
  bucket = var.raw_bucket_name

  tags = {
    Name = "newsapi-raw-articles"
  }
}

# (Optional) enable versioning, encryption, etc. as needed

############################
# SQS Queue               #
############################

resource "aws_sqs_queue" "raw_articles_queue" {
  name                       = "${var.env}-raw-articles-queue"
  visibility_timeout_seconds = 305
  message_retention_seconds  = 345600 # 4 days
}

############################
# Lambda Layer            #
############################

# NOTE: You will need to create the layer ZIP separately, e.g.
# a directory like:
#  layer/python/requirements.txt  (with requests, etc.)
# and build a zip e.g. newsapi_layer.zip
#
# For now, this is just wired to a placeholder file path.

resource "aws_lambda_layer_version" "newsapi_deps_layer" {
  filename         = "${path.module}/NewsIngestor_python_dependency_layer.zip"
  layer_name       = "NewsIngestor_python_dependency_layer"
  source_code_hash = filebase64sha256("${path.module}/NewsIngestor_python_dependency_layer.zip")

  compatible_runtimes = [
    local.pythonVersion
  ]

  description = "Dependencies for NewsAPI ingestion lambda"
}

############################
# Lambda Function         #
############################

resource "aws_lambda_function" "newsapi_headline_ingestion" {
  function_name = local.newsapi_headline_ingestion_lambda_name
  role          = data.aws_iam_role.newsapi_lambda_role.arn
  runtime       = local.pythonVersion
  handler       = "newsapi_ingestor.handler"

  filename         = "${path.module}/NewsIngestor.zip"
  source_code_hash = filebase64sha256("${path.module}/NewsIngestor.zip")
  timeout          = 300
  memory_size      = 150

  layers = [
    aws_lambda_layer_version.newsapi_deps_layer.arn
  ]

  environment {
    variables = {
      RAW_BUCKET_NAME        = aws_s3_bucket.raw_articles.bucket
      RAW_ARTICLES_QUEUE_URL = aws_sqs_queue.raw_articles_queue.url
      SOURCE_ID              = "newsapi"
      NEWS_API_KEY           = var.newsapi_api_key
      NEWSAPI_COUNTRY        = var.country
      NEWSAPI_LANGUAGE       = var.language
      NEWSAPI_CATEGORY       = ""
      PREFIX_KEY             = var.RAW_BUCKET_INPUT_KEY
    }
  }
  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.newsingestor_sg_id]
  }
}

output "raw_articles_sqs_queue_arn" {
  value = aws_sqs_queue.raw_articles_queue.arn
}

output "raw_articles_bucket_url" {
  value = aws_s3_bucket.raw_articles.id
}

# (Optional) EventBridge rule to trigger Lambda on a schedule
# resource "aws_cloudwatch_event_rule" "newsapi_schedule" {
#   name                = "newsapi-headline-ingestion-schedule"
#   schedule_expression = "rate(60 minutes)"
# }
#
# resource "aws_cloudwatch_event_target" "newsapi_schedule_target" {
#   rule      = aws_cloudwatch_event_rule.newsapi_schedule.name
#   target_id = "newsapi_headline_ingestion_target"
#   arn       = aws_lambda_function.newsapi_headline_ingestion.arn
# }
#
# resource "aws_lambda_permission" "allow_eventbridge_invoke" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.newsapi_headline_ingestion.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.newsapi_schedule.arn
# }