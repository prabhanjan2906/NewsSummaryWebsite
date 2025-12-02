variable "REGION" {
  description = "working region in aws"
  type        = string
}

provider "aws" {
  region = var.REGION
}

terraform {
  backend "s3" {}
}