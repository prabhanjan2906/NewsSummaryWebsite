data "aws_lambda_function" "headlines" {
  function_name = local.lambda_function_name
}

output "lambda_function_arn" {
  value = data.aws_lambda_function.headlines.arn
}

output "headlines_lambda_function_name" {
  value = data.aws_lambda_function.headlines 
}

data "aws_lambda_function" "headlinesinvalid" {
  function_name = "invalid-function-name"
}
output "lambda_function_arn_invalid" {
  value = data.aws_lambda_function.headlinesinvalid.arn
}
output "headlines_lambda_function_name_invalid" {
  value = data.aws_lambda_function.headlinesinvalid
}