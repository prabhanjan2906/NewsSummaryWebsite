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
