locals {
  s3_prefix = "*"
}

data "aws_iam_policy_document" "s3_write" {
  statement {
    sid    = "S3WriteObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::${var.RAW_BUCKET}/${local.s3_prefix}"
    ]
  }

  statement {
    sid    = "S3BucketMeta"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [
      "arn:aws:s3:::${var.RAW_BUCKET}"
    ]
  }
}

# resource "aws_iam_role_policy" "s3_write" {
#   name   = "webpagescraper_s3_write_policy"
#   role   = aws_iam_role.news_consumer_exec.id
#   policy = data.aws_iam_policy_document.s3_write.json
# }

resource "aws_s3_bucket" "raw_data_storage_for_webpage_scraper" {
  bucket = var.RAW_BUCKET
  tags = {
    Name        = "webpage_scraper_s3_bucket"
    Environment = var.ENVIRONMENT
  }
}