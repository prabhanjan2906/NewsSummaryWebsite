variable "RAW_BUCKET" {
  description = "S3 bucket to store scraped raw webpage data"
  type        = string
}

variable "ENVIRONMENT" {
  description = "Target environment to run"
  type        = string
}
