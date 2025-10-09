provider "aws" {
  region = var.REGION
}

terraform {
  backend "s3" {}
}