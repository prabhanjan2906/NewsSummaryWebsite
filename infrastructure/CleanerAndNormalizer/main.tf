############################
# SQS for next stage      #
############################

resource "aws_sqs_queue" "article_ready_for_clustering_queue" {
  name                       = "article-ready-for-clustering-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 days
}

############################
# Lambda: article_cleaner  #
############################

resource "aws_lambda_layer_version" "article_cleaner_normalizer_dependency_layer" {
  filename         = "${path.module}/CleanerAndNormalizer_python_dependency_layer.zip"
  layer_name       = "CleanerAndNormalizer_python_dependency_layer"
  source_code_hash = filebase64sha256("${path.module}/CleanerAndNormalizer_python_dependency_layer.zip")

  compatible_runtimes = [
    local.pythonVersion
  ]

  description = "Dependencies for CleanerAndNormalizer lambda"
}

# NOTE: build this zip file yourself containing cleaner_app.py as handler module
resource "aws_lambda_function" "article_cleaner_normalizer" {
  function_name = "${var.env}-article_cleaner_normalizer"
  role          = data.aws_iam_role.article_cleaner_lambda_role.arn
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
      DB_NAME     = aws_db_instance.newsdb.db_name
      DB_USER     = aws_db_instance.newsdb.username
      DB_PASSWORD = aws_db_instance.newsdb.password
    }
  }

  layers = [
    aws_lambda_layer_version.article_cleaner_normalizer_dependency_layer.arn
  ]

  timeout     = 300
  memory_size = 150
  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.lambda_sg]
  }
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
