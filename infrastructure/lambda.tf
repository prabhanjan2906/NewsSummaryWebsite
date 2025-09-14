# Lambda function using python3.9
resource "aws_lambda_function" "news_summary" {
  function_name = "news-summary-function"
  filename      = "lambda_function_payload.zip" # Update with your deployment package path
  handler       = "index.handler"
  runtime       = "python3.9"
  role          = data.aws_iam_role.github_actions_role.arn

  environment {
    variables = {
      ENVIRONMENT = "development"
      LANGUAGE    = "en"
      COUNTRY     = var.COUNTRY
    }
  }
}

# Reference to existing IAM role
# If the role is already created outside Terraform, use data source instead:
data "aws_iam_role" "github_actions_role" {
  name = "GithubActionsRole"
}

# If you want to create the role in Terraform, replace the data block above with a resource block.
