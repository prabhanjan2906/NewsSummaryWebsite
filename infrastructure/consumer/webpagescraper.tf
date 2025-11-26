# data "aws_iam_policy_document" "consumer_lambda_trust" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "news_consumer_exec" {
#   name               = "news-consumer-exec"
#   assume_role_policy = data.aws_iam_policy_document.consumer_lambda_trust.json
# }

# data "aws_iam_policy" "consumer_lambda_basic" {
#   name        = "AWSLambdaBasicExecutionRole"
#   path_prefix = "/service-role/"
# }

# resource "aws_iam_role_policy_attachment" "consumer_policy_attach" {
#   role       = aws_iam_role.news_consumer_exec.name
#   policy_arn = data.aws_iam_policy.consumer_lambda_basic.arn
# }

# data "aws_iam_policy_document" "sqs_consume" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "sqs:ReceiveMessage",
#       "sqs:DeleteMessage",
#       "sqs:ChangeMessageVisibility",
#       "sqs:GetQueueAttributes",
#       "sqs:GetQueueUrl"
#     ]
#     resources = [var.newsapi_message_queue_arn]
#   }
# }

# resource "aws_iam_policy" "sqs_consume" {
#   name   = "webpage-scraper-sqs-consume"
#   policy = data.aws_iam_policy_document.sqs_consume.json
# }
# resource "aws_iam_role_policy_attachment" "sqs_consume_attach" {
#   role       = aws_iam_role.news_consumer_exec.name
#   policy_arn = aws_iam_policy.sqs_consume.arn
# }

# resource "aws_lambda_layer_version" "webpagescraper_python_dependency" {
#   layer_name          = "webpagescraper_python_dependency_installer"
#   filename            = "${path.module}/webpagescraper_python_dependency_layer.zip"
#   compatible_runtimes = [var.python_version_for_lambda]
#   source_code_hash    = filebase64sha256("${path.module}/webpagescraper_python_dependency_layer.zip")
#   description         = "Lambda Layer for webscraper"
# }

# resource "aws_lambda_function" "consumer_webscraper" {
#   function_name    = "newsapi-url-webscraper"
#   role             = aws_iam_role.news_consumer_exec.arn
#   runtime          = var.python_version_for_lambda
#   handler          = "webpagescraper_entrypoint.handler"
#   filename         = "${path.module}/lambda_web_page_scraper.zip"
#   source_code_hash = filebase64sha256("${path.module}/lambda_web_page_scraper.zip")

#   timeout     = 300
#   memory_size = 512

#   # Uncomment later after setting up VPC:
#   # vpc_config {
#   #   subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
#   #   security_group_ids = [aws_security_group.lambda_vpc.id]
#   # }
#   environment {
#     variables = {
#       ENVIRONMENT = var.ENVIRONMENT
#       RAW_BUCKET  = var.RAW_BUCKET
#       PREFIX_KEY  = var.RAW_BUCKET_INPUT_KEY
#     }
#   }
#   layers = [aws_lambda_layer_version.webpagescraper_python_dependency.arn]
# }

# resource "aws_lambda_event_source_mapping" "articles_to_consumer" {
#   event_source_arn = var.newsapi_message_queue_arn
#   function_name    = aws_lambda_function.consumer_webscraper.arn

#   # Small batches isolate failures & reduce re-drives
#   batch_size                         = 5
#   maximum_batching_window_in_seconds = 5 # small latency buffer

#   # Enable partial-batch failure reporting (recommended)
#   function_response_types = ["ReportBatchItemFailures"]
# }