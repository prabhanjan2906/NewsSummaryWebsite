############################
# DB connection vars      #
############################

variable "db_name" {
  description = "Postgres database name"
  type        = string
}

variable "db_user" {
  description = "Postgres user"
  type        = string
}

variable "db_password" {
  description = "Postgres password"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  type = string
}

variable "input_sqs_raw_queue_arn" {
}

variable "raw_articles_bucket_name" {}

variable "raw_articles_bucket_url" {}

variable "rds_sg_id" {}

variable "lambda_sg" {}

variable "private_subnets" {}

variable "SubnetsCount" {
  type    = number
  default = 2
}

variable "execution_role" {
  description = "Execution Role Name"
  type        = string
}
