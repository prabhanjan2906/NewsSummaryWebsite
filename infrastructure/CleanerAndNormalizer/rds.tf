resource "aws_db_instance" "newsdb" {
  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = "db.t3.micro"
  identifier        = "${var.env}-news-db"
  username          = var.db_user
  password          = var.db_password
  allocated_storage = 20

  publicly_accessible = false
  skip_final_snapshot = true
}
