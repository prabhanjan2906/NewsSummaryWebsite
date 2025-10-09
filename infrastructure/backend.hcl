bucket         = "tfstatefiles3bucket-newssummarywebsite"
key            = "newssummarywebsite/__REGION__/terraform.tfstate"
region         = "__REGION__"
dynamodb_table = "TerraformStateFileLockVariableTable"
encrypt        = true