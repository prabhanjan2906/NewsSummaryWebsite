variable "GCP_TERRAFORM_SERVICE_ACCOUNT_EMAIL" {
  type = string
}

variable "TERRAFORM_STATE_STORAGE_BUCKET_NAME" {
  type = string
}

# Project-level roles for the Terraform runner SA
resource "google_project_iam_member" "tf_sa_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${var.GCP_TERRAFORM_SERVICE_ACCOUNT_EMAIL}"
}

resource "google_project_iam_member" "tf_sa_serviceusage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${var.GCP_TERRAFORM_SERVICE_ACCOUNT_EMAIL}"
}

# Bucket access for remote state
resource "google_storage_bucket_iam_member" "tf_state_object_admin" {
  bucket = var.TERRAFORM_STATE_STORAGE_BUCKET_NAME
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.GCP_TERRAFORM_SERVICE_ACCOUNT_EMAIL}"
}

# (Optional) Workload Identity binding for GitHub
# resource "google_iam_workload_identity_pool" ...
# resource "google_iam_workload_identity_pool_provider" ...
# resource "google_service_account_iam_member" "wif_user" {
#   service_account_id = google_service_account.terraform_sa.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "principalSet://iam.googleapis.com/${pool_id}/attribute.repository/your-org/your-repo"
# }
