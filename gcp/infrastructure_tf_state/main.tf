locals {
  required_apis = [
    "iam.googleapis.com",              # IAM for SAs/roles
    "cloudresourcemanager.googleapis.com",
    "storage.googleapis.com",          # Cloud Storage
  ]
}

module "api_enable" {
  source = "../identity/api_enable"
  project_id = var.GCP_PROJECT_ID
  terraform_sa_name = var.GCP_SA_NAME
  required_apis_to_enable = local.required_apis
}

module "service_account" {
  source = "../identity/service_account"
  project_id = var.GCP_PROJECT_ID
  terraform_sa_name = var.GCP_SA_NAME
  required_apis_to_enable = local.required_apis
  apis_enabled = module.api_enable.required
}

module "TerraformStateStorage" {
  source = "./StateStorage"
  GCP_PROJECT_ID = var.GCP_PROJECT_ID
  TERRAFORM_STATE_STORAGE_BUCKET_NAME = var.TERRAFORM_STATE_STORAGE_BUCKET_NAME
  REGION = var.REGION
}
