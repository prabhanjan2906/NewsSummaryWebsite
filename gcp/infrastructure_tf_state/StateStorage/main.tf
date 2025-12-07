resource "google_storage_bucket" "tf_state" {
  name     = var.TERRAFORM_STATE_STORAGE_BUCKET_NAME
  location = var.REGION

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}
