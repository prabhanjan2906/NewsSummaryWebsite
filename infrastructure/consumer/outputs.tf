output "python_dependency_layer_arn" {
  value = aws_lambda_layer_version.webpagescraper_python_dependency.arn
}

output "raw_data_storage_for_webpage_scraper_id" {
  value = aws_s3_bucket.raw_data_storage_for_webpage_scraper.id
}