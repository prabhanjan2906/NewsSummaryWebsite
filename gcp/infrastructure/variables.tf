variable "GCP_PROJECT_ID" {
  type        = string
  description = "GCP project ID"
}

variable "REGION" {
  type        = string
  description = "GCP region (e.g. us-central1)"
  default     = "us-central1"
}

variable "GCP_TERRAFORM_SERVICE_ACCOUNT_EMAIL" {
  type        = string
  description = "Service account used by Terraform (GitHub Actions)."
}

variable "GCP_PROJECT_NUMBER" {
  type = string
}

variable "GCP_SA_NAME" {
  type        = string
  description = "GCP Service Account Name"
}
