resource "google_project_service" "required" {
  for_each = toset(var.required_apis_to_enable)

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

output "required" {
  value = google_project_service.required
}