variable "REGION" {
  description = "working region in aws"
  type        = string
}

locals {
  region = var.REGION
}