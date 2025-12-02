variable "NEWS_API_KEY" {
  description = "API key for News API"
  type        = string
  sensitive   = true
}

variable "COUNTRY" {
  description = "country to fetch news articles from"
  type        = string
}

variable "LANGUAGE" {
  description = "language of the news articles"
  type        = string
}

variable "RAW_BUCKET_INPUT_KEY" {
  description = "raw articles storage prefix"
  type        = string
}

variable "RAW_BUCKET" {
  description = "raw bucket name"
  type        = string
}
