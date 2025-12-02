############################
# IAM Role & Policies     #
############################

# Custom policy for S3 + SQS
resource "aws_iam_policy" "newsapi_lambda_policy" {
  name        = "${var.env}-newsapi_headline_ingestion_policy"
  description = "Allow lambda to write to S3 raw bucket and send messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Write"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.raw_articles.bucket}/*"
        ]
      },
      {
        Sid    = "AllowSQSSend"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.raw_articles_queue.arn
      },
      {
        Sid    = "AllowEC2DescribeForTerraform",
        Effect = "Allow",
        Action = [
          "ec2:AllocateAddress",
          "ec2:CreateTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNatGateways",
          "ec2:DescribeAddresses",
          "ec2:CreateVpc",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeAddressesAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "newsapi_lambda_policy_attach" {
  # role       = aws_iam_role.newsapi_lambda_role.name
  role       = var.execution_role
  policy_arn = aws_iam_policy.newsapi_lambda_policy.arn
}

data "aws_iam_role" "newsapi_lambda_role" {
  name = var.execution_role
}
