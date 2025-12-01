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
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 days
}

############################
# IAM Role & Policies     #
############################

# Lambda execution role
resource "aws_iam_role" "newsapi_lambda_role" {
  name = "${var.env}-newsapi_headline_ingestion_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Basic Lambda logging permissions
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.newsapi_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for S3 + SQS
resource "aws_iam_policy" "newsapi_lambda_policy" {
  name        = "${var.env}-newsapi_headline_ingestion_policy"
  description = "Allow lambda to write to S3 raw bucket and send messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Write"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.raw_articles.bucket}/*"
        ]
      },
      {
        Sid    = "AllowSQSSend"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.raw_articles_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "newsapi_lambda_policy_attach" {
  role       = aws_iam_role.newsapi_lambda_role.name
  policy_arn = aws_iam_policy.newsapi_lambda_policy.arn
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
  role          = aws_iam_role.newsapi_lambda_role.arn
  runtime       = local.pythonVersion
  handler       = "newsapi_ingestor.handler"

  filename         = "${path.module}/NewsIngestor.zip"
  source_code_hash = filebase64sha256("${path.module}/NewsIngestor.zip")
  timeout          = 300
  memory_size      = 512

  layers = [
    aws_lambda_layer_version.newsapi_deps_layer.arn
  ]

  environment {
    variables = {
      RAW_BUCKET_NAME        = aws_s3_bucket.raw_articles.bucket
      RAW_ARTICLES_QUEUE_URL = aws_sqs_queue.raw_articles_queue.url
      SOURCE_ID              = "newsapi"
      NEWS_API_KEY        = var.newsapi_api_key
      NEWSAPI_COUNTRY        = var.country
      NEWSAPI_LANGUAGE       = var.language
      NEWSAPI_CATEGORY       = ""
      PREFIX_KEY             = var.RAW_BUCKET_INPUT_KEY
    }
  }
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