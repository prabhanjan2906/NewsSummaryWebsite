bucket         = "tfstatefiles3bucket-newssummarywebsite"
key            = "newssummarywebsite/prod/terraform.tfstate"
region         = "us-east-2"
dynamodb_table = "TerraformStateFileLockVariableTable"
encrypt        = true