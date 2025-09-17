data "aws_iam_policy_document" "scheduler_trust" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    principals { 
        type = "Service"
        identifiers = ["scheduler.amazonaws.com"] 
    }
  }
}
resource "aws_iam_role" "newsapi_scheduler_invoke_role" {
  name               = "newsapi-fetcher-scheduler-invoke-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_trust.json
}

data "aws_iam_policy_document" "invoke_lambda" {
  statement {
    effect   = "Allow"
    actions  = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.headlines.arn]
  }
}
resource "aws_iam_policy" "invoke_lambda" {
  name   = "scheduler-invoke-policy-newsapi-fetcher"
  policy = data.aws_iam_policy_document.invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "invoke_attach" {
  role       = aws_iam_role.newsapi_scheduler_invoke_role.name
  policy_arn = aws_iam_policy.invoke_lambda.arn
}

resource "aws_scheduler_schedule" "newsapi_fetch_scheduler" {
  name                = "newsapi_fetch_scheduler"
  schedule_expression = local.lambda_schedule_rate
  flexible_time_window { mode = "OFF" }

  target {
    arn      = data.aws_lambda_function.headlines.arn
    role_arn = aws_iam_role.newsapi_scheduler_invoke_role.arn
  }
}