data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"] 
    }
  }
}
resource "aws_iam_role" "news_fetcher_exec" {
  name               = local.news_fetcher_exec_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy" "lambda_basic_execution_role" {
  name        = "AWSLambdaBasicExecutionRole"
  path_prefix = "/service-role/"
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.news_fetcher_exec.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution_role.arn
}

# Lambda function using python3.9
resource "aws_lambda_function" "news_headlines" {
  function_name = local.lambda_function_name
  filename = "${path.module}/lambda_news_api_fetcher.zip"
  handler  = "headlines_entry_point.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.news_fetcher_exec.arn
  source_code_hash = filebase64sha256("${path.module}/lambda_news_api_fetcher.zip")

  environment {
    variables = {
      ENVIRONMENT  = "development"
      NEWS_API_KEY = var.NEWS_API_KEY
      LANGUAGE     = var.LANGUAGE
      COUNTRY      = var.COUNTRY
      NEWSAPI_OUTPUT_QUEUE_URL = aws_sqs_queue.newsAPI_producer_queue.url
    }
  }
}

# Reference to existing IAM role
# since the role is already created outside Terraform and on console manually, use data source instead:
data "aws_iam_role" "github_actions_role" {
  name = "GithubActionsRole"
}

# NOTE: add a VPC and restrict lambda access to internet. If attached to a VPC, the VPC has a NAT gateway or NAT instance and proper route table configuration.

data "aws_lambda_function" "headlines" {
  function_name = local.lambda_function_name
}

output "newsapi_fetcher_lambda_function_arn" {
  value = data.aws_lambda_function.headlines.arn
}