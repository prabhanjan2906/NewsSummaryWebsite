############################
# SQS for next stage      #
############################

resource "aws_sqs_queue" "article_ready_for_clustering_queue" {
  name                       = "article-ready-for-clustering-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 days
}

############################
# IAM Role for Cleaner    #
############################

resource "aws_iam_role" "article_cleaner_lambda_role" {
  name = "article_cleaner_normalizer_role"

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

# Basic logging
resource "aws_iam_role_policy_attachment" "article_cleaner_lambda_basic" {
  role       = aws_iam_role.article_cleaner_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for S3 + SQS
resource "aws_iam_policy" "article_cleaner_lambda_policy" {
  name        = "article_cleaner_normalizer_policy"
  description = "Allow cleaner lambda to read from S3 raw bucket, read from raw-articles-queue, and send to article-ready-for-clustering-queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Read"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.raw_articles_bucket_name}/*"
        ]
      },
      {
        Sid    = "AllowSQSPollRaw"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = var.input_sqs_raw_queue_arn
      },
      {
        Sid    = "AllowSQSSendToNext"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.article_ready_for_clustering_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "article_cleaner_lambda_policy_attach" {
  role       = aws_iam_role.article_cleaner_lambda_role.name
  policy_arn = aws_iam_policy.article_cleaner_lambda_policy.arn
}

############################
# Lambda: article_cleaner  #
############################

# NOTE: build this zip file yourself containing cleaner_app.py as handler module
resource "aws_lambda_function" "article_cleaner_normalizer" {
  function_name = "article_cleaner_normalizer"
  role          = aws_iam_role.article_cleaner_lambda_role.arn
  runtime       = local.pythonVersion
  handler       = "cleaner_and_normalizer.handler"

  filename         = "${path.module}/CleanerAndNormalizer.zip"
  source_code_hash = filebase64sha256("${path.module}/CleanerAndNormalizer.zip")

  # If you bundle psycopg2 etc. into the ZIP, no layer is needed.
  # Or you can add a DB deps layer here the same way you did for NewsAPI deps.

  environment {
    variables = {
      RAW_BUCKET_NAME                        = var.raw_articles_bucket_name
      RAW_ARTICLES_QUEUE_URL                 = var.raw_articles_bucket_url
      ARTICLE_READY_FOR_CLUSTERING_QUEUE_URL = aws_sqs_queue.article_ready_for_clustering_queue.id

      DB_HOST     = aws_db_instance.newsdb.address
      DB_PORT     = aws_db_instance.newsdb.port
      DB_NAME     = var.db_name
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
    }
  }

  timeout     = 300
  memory_size = 512
}

############################
# SQS → Lambda trigger     #
############################

resource "aws_lambda_event_source_mapping" "raw_articles_to_cleaner" {
  event_source_arn = var.input_sqs_raw_queue_arn
  function_name    = aws_lambda_function.article_cleaner_normalizer.arn
  batch_size       = 10
  enabled          = true
}
