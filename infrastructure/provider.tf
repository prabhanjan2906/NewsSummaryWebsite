provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {}
}