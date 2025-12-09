variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "terraform_sa_name" {
  type        = string
  description = "Service account ID for GitHub Actions Terraform"
}

variable "required_apis_to_enable" {
  type = list(string)
}