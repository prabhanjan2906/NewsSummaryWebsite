variable "newsapi_message_queue_arn" {
  description = "ARN of the SQS queue to which the news fetcher Lambda will send messages"
  type        = string
}
