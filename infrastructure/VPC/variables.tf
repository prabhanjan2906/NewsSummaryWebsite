variable "region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  type = string
}

variable "SubnetsCount" {
  type    = number
  default = 2
}