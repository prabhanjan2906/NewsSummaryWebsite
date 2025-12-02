variable "REGION" {
  description = "working region in aws"
  type        = string
  default = "us-east-2"
}

locals {
  region = var.REGION
}