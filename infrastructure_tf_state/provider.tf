provider "aws" {
  region = var.REGION
}

provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}
