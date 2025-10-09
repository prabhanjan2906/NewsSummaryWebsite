provider "aws" {
  region = var.REGION
}

terraform {
  backend "s3" {}
}

provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}
