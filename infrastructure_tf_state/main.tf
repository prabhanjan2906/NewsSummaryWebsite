module "terraform" {
  source            = "./terraform_state_storage"
  REGION            = local.region
  state_bucket_name = "tfstatefiles3bucket-newssummarywebsite"
  lock_table_name   = "TerraformStateFileLockVariableTable"
}