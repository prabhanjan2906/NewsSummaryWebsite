variable "apis_enabled" {}

// Service account used by GitHub Actions (Terraform runner)
resource "google_service_account" "terraform_sa" {
  account_id   = var.terraform_sa_name
  display_name = "News Summary SA"
  depends_on = [var.apis_enabled]
}

// Grant it project-level roles (start with Editor; later narrow down)
resource "google_project_iam_member" "terraform_sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
  depends_on = [ google_service_account.terraform_sa ]
}
