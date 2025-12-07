variable "region" {
  description = "AWS region"
  type        = string
}

variable "raw_bucket_name" {
  description = "Name of the S3 bucket for raw ingested articles"
  type        = string
  default     = "webpage-scraper-raw-json-storage"
}

variable "newsapi_api_key" {
  description = "API key for NewsAPI"
  type        = string
  sensitive   = true
}

variable "country" {
  type = string
}

variable "language" {
  type = string
}

variable "env" {
  type = string
}

variable "RAW_BUCKET_INPUT_KEY" {
  description = "raw articles storage prefix"
  type        = string
}

variable "RAW_BUCKET" {
  description = "raw bucket name"
  type        = string
}

variable "newsingestor_sg_id" {}

variable "private_subnets" {}

variable "SubnetsCount" {
  type    = number
  default = 2
}

variable "execution_role" {
  description = "Execution Role Name"
  type        = string
}
