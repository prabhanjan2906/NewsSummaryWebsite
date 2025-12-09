terraform {
  # Use local backend temporarily
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.REGION
}
