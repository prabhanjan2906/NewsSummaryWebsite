# Lambda function using python3.9
resource "aws_lambda_function" "news_headlines" {
  function_name = "news_headlines_function"
  filename      = "newsapi.zip" # Update with your deployment package path
  handler       = "headlines_entry_point.handler"
  runtime       = "python3.9"
  role          = data.aws_iam_role.github_actions_role.arn

  environment {
    variables = {
      ENVIRONMENT  = "development"
      NEWS_API_KEY = var.NEWS_API_KEY
      LANGUAGE     = "en"
      COUNTRY      = var.COUNTRY
    }
  }
}

# Reference to existing IAM role
# If the role is already created outside Terraform, use data source instead:
data "aws_iam_role" "github_actions_role" {
  name = "GithubActionsRole"
}

# If you want to create the role in Terraform, replace the data block above with a resource block.
# NOTE: add a VPC and restrict lambda access to internet. If attached to a VPC, the VPC has a NAT gateway or NAT instance and proper route table configuration.