module "identity" {
  source    = "./identity"
  role_name = local.execution_role
}

module "vpc" {
  # count        = module.identity.is_identity_deployed
  source       = "./VPC"
  region       = var.REGION
  env          = var.ENVIRONMENT
  SubnetsCount = 2
  depends_on   = [module.identity]
}

module "NewsIngestor" {
  source               = "./NewsIngestor"
  region               = var.REGION
  env                  = var.ENVIRONMENT
  newsapi_api_key      = var.NEWS_API_KEY
  language             = var.LANGUAGE
  country              = var.COUNTRY
  RAW_BUCKET_INPUT_KEY = var.RAW_BUCKET_INPUT_KEY
  RAW_BUCKET           = var.RAW_BUCKET
  newsingestor_sg_id   = module.vpc.newsingestor_sg_id
  private_subnets      = module.vpc.private_subnets_id
  SubnetsCount         = 2
  depends_on           = [module.vpc]
  execution_role       = local.execution_role
}

module "CleanerAndNormalizer" {
  source                   = "./CleanerAndNormalizer"
  input_sqs_raw_queue_arn  = module.NewsIngestor.raw_articles_sqs_queue_arn
  raw_articles_bucket_name = var.RAW_BUCKET
  raw_articles_bucket_url  = module.NewsIngestor.raw_articles_bucket_url
  region                   = var.REGION
  env                      = var.ENVIRONMENT
  db_name                  = var.DB_NAME
  db_password              = var.DB_PASSWORD
  db_user                  = var.DB_USER
  rds_sg_id                = module.vpc.rds_sg_id
  lambda_sg                = module.vpc.newsingestor_sg_id
  private_subnets          = module.vpc.private_subnets_id
  SubnetsCount             = 2
  depends_on               = [module.vpc]
  execution_role           = local.execution_role
}