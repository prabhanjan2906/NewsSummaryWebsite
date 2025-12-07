variable "DB_NAME" {
  description = "Postgres database name"
  type        = string
}

variable "DB_USER" {
  description = "Postgres user"
  type        = string
}

variable "DB_PASSWORD" {
  description = "Postgres password"
  type        = string
  sensitive   = true
}
