locals {
  required_apis = [
    "compute.googleapis.com",          # if you use GCE / MIGs
    "cloudkms.googleapis.com",         # if you use KMS
    "cloudfunctions.googleapis.com",   # if using Cloud Functions
    "run.googleapis.com",              # if using Cloud Run
  ]
}

module "identity_policy" {
  source = "../identity/policies"
  project_id = var.GCP_PROJECT_ID
  terraform_sa_name = var.GCP_SA_NAME
  TERRAFORM_STATE_STORAGE_BUCKET_NAME = var.TERRAFORM_STATE_STORAGE_BUCKET_NAME
  required_apis_to_enable = local.required_apis
  GCP_TERRAFORM_SERVICE_ACCOUNT_EMAIL = var.GCP_TERRAFORM_SERVICE_ACCOUNT_EMAIL
}

module "identity" {
  source = "../identity/api_enable"
  project_id = var.GCP_PROJECT_ID
  terraform_sa_name = var.GCP_SA_NAME
  required_apis_to_enable = local.required_apis
}