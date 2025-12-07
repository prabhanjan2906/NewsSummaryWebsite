module "terraform" {
  source            = "./terraform_state_storage"
  region            = local.region
  state_bucket_name = "${local.region}-tfstatefiles3bucket-newssummarywebsite"
  lock_table_name   = "${local.region}-TerraformStateFileLockVariableTable"
}