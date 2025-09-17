# Lambda function using python3.9
resource "aws_lambda_function" "news_headlines" {
  function_name = local.lambda_function_name
  filename = "${path.module}/lambda_news_api_fetcher.zip"
  handler  = "headlines_entry_point.handler"
  runtime       = "python3.9"
  role          = data.aws_iam_role.github_actions_role.arn

  environment {
    variables = {
      ENVIRONMENT  = "development"
      NEWS_API_KEY = var.NEWS_API_KEY
      LANGUAGE     = var.LANGUAGE
      COUNTRY      = var.COUNTRY
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