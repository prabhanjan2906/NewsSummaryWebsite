locals {
  ONE_SECOND = 1
  ONE_MINUTE = 60 * local.ONE_SECOND
  ONE_HOUR   = 60 * local.ONE_MINUTE
  ONE_DAY    = 24 * local.ONE_HOUR
}

resource "aws_sqs_queue" "newsAPI_producer_dlq" {
  name = "newsAPI-producer-dlq"
}

resource "aws_sqs_queue" "newsAPI_producer_queue" {
  name                       = "newsAPI-producer-queue"
  visibility_timeout_seconds = 301               # > consumer Lambda has 300 seconds timeout
  message_retention_seconds  = local.ONE_DAY * 4 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.newsAPI_producer_dlq.arn
    maxReceiveCount     = 5
  })
}

data "aws_iam_policy_document" "sqs_send" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.newsAPI_producer_queue.arn]
  }
}

resource "aws_iam_policy" "sqs_send" {
  name   = "news-fetcher-sqs-send"
  policy = data.aws_iam_policy_document.sqs_send.json
}

resource "aws_iam_role_policy_attachment" "lambda_fetcher_can_send_messages_to_producer_queue" {
  role       = aws_iam_role.news_fetcher_exec.name
  policy_arn = aws_iam_policy.sqs_send.arn
}

output "newsapi_message_queue_arn" {
  value = aws_sqs_queue.newsAPI_producer_queue.arn
}