resource "aws_s3_bucket" "raw_data_storage_for_webpage_scraper" {
  bucket = var.RAW_BUCKET
  tags = {
    Name        = "webpage_scraper_s3_bucket"
    Environment = var.ENVIRONMENT
  }
}