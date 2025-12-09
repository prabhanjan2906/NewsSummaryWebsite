variable "GCP_PROJECT_ID" {
  type        = string
  description = "GCP project ID"
}

variable "REGION" {
  type        = string
  description = "GCP region (e.g. us-central1)"
}

variable "TERRAFORM_STATE_STORAGE_BUCKET_NAME" {
  type = string
}
