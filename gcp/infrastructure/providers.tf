variable "TERRAFORM_STATE_STORAGE_BUCKET_NAME" {
  type        = string
  description = "State File Storage bucket name"
}

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Recommended: use a GCS bucket for remote state
  backend "gcs" {}
}

provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.REGION
}
