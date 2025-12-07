# SG for Lambdas (Cleaner, Ingestion, etc.)
resource "aws_security_group" "lambda_sg" {
  name        = "${var.env}-news-lambda-sg"
  description = "Security group for Lambdas in news-vpc"
  vpc_id      = aws_vpc.news_vpc.id

  # outbound allowed so Lambdas can reach RDS + internet via NAT
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-news-lambda-sg"
  }
}

# SG for RDS (only allow from Lambda SG on 5432)
resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-news-rds-sg"
  description = "Security group for newsdb RDS Postgres"
  vpc_id      = aws_vpc.news_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-news-rds-sg"
  }
}

output "newsingestor_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
