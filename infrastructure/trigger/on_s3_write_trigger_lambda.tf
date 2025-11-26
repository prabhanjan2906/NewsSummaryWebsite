# data "aws_iam_policy_document" "lambda_trust" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "lambda_exec" {
#   name               = "s3-to-bedrock-executor"
#   assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
# }

# resource "aws_iam_role_policy" "lambda_policy" {
#   role = aws_iam_role.lambda_exec.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       { Sid    = "S3Read", Effect = "Allow",
#         Action = ["s3:GetObject"],
#       Resource = "arn:aws:s3:::${var.RAW_BUCKET}/${var.RAW_BUCKET_INPUT_KEY}/*" },
#       { Sid    = "S3Write", Effect = "Allow",
#         Action = ["s3:PutObject"],
#       Resource = "arn:aws:s3:::${var.RAW_BUCKET}/${var.RAW_BUCKET_OUTPUT_KEY}/*" },
#       { Sid = "Bedrock", Effect = "Allow",
#         Action = [
#           "bedrock:Converse", "bedrock:ConverseStream",
#           "bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"
#         ],
#       Resource = "*" },
#       { Sid    = "Logs", Effect = "Allow",
#         Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
#       Resource = "*" }
#     ]
#   })
# }

# resource "aws_lambda_function" "processor" {
#   function_name    = "s3-to-bedrock"
#   role             = aws_iam_role.lambda_exec.arn
#   handler          = "s3_write_trigger_lambda.handler"
#   runtime          = var.python_version_for_lambda
#   filename         = "${path.module}/trigger.zip"
#   source_code_hash = filebase64sha256("${path.module}/trigger.zip")
#   timeout          = 300
#   memory_size      = 512

#   environment {
#     variables = {
#       REGION        = var.REGION
#       MODEL_ID      = var.MODEL_ID
#       INPUT_PREFIX  = var.RAW_BUCKET_INPUT_KEY
#       OUTPUT_PREFIX = var.RAW_BUCKET_OUTPUT_KEY
#     }
#   }
#   layers = [var.python_dependency_layer_arn]
# }

# resource "aws_s3_bucket_notification" "notify" {
#   bucket = var.raw_data_storage_for_webpage_scraper_id
#   lambda_function {
#     lambda_function_arn = aws_lambda_function.processor.arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = var.RAW_BUCKET_INPUT_KEY
#     filter_suffix       = ".json"
#   }
# }

# # grant access to S3 to invoke Lambda
# resource "aws_lambda_permission" "allow_s3" {
#   statement_id  = "AllowS3Invoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.processor.function_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = var.raw_data_storage_for_webpage_scraper_arn
# }