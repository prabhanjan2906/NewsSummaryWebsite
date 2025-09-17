data "aws_iam_policy_document" "consumer_lambda_trust" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals { 
        type = "Service"
        identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "news_consumer_exec" {
  name               = "news-consumer-exec"
  assume_role_policy = data.aws_iam_policy_document.consumer_lambda_trust.json
}

data "aws_iam_policy" "consumer_lambda_basic" {
  name        = "AWSLambdaBasicExecutionRole"
  path_prefix = "/service-role/"
}

resource "aws_iam_role_policy_attachment" "consumer_policy_attach" {
  role       = aws_iam_role.news_consumer_exec.name
  policy_arn = data.aws_iam_policy.consumer_lambda_basic.arn
}

data "aws_iam_policy_document" "sqs_consume" {
  statement {
    effect  = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    resources = [var.newsapi_message_queue_arn]
  }
}

resource "aws_iam_policy" "sqs_consume" {
  name   = "webpage-scraper-sqs-consume"
  policy = data.aws_iam_policy_document.sqs_consume.json
}
resource "aws_iam_role_policy_attachment" "sqs_consume_attach" {
  role       = aws_iam_role.news_consumer_exec.name
  policy_arn = aws_iam_policy.sqs_consume.arn
}