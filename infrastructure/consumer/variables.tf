variable "newsapi_message_queue_arn" {
  description = "ARN of the SQS queue to which the news fetcher Lambda will send messages"
  type        = string
}

variable "RAW_BUCKET" {
  description = "S3 bucket to store scraped raw webpage data"
  type        = string
}
