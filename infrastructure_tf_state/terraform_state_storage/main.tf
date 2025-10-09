resource "aws_s3_bucket" "tf_state" {
  provider = aws.use2
  bucket = var.state_bucket_name
}

resource "aws_kms_key" "tf_state" {
  description         = "KMS key for Terraform state"
  enable_key_rotation = true
  depends_on = [ aws_s3_bucket.tf_state ]
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { 
    status = "Enabled" 
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tf_state.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  depends_on = [ aws_s3_bucket.tf_state ]
}

output "bucket" { value = aws_s3_bucket.tf_state.bucket }
output "table"  { value = aws_dynamodb_table.tf_lock.name }
output "kms"    { value = aws_kms_key.tf_state.arn }
