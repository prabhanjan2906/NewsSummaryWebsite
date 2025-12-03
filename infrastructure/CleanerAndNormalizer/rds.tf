resource "aws_iam_policy" "github_actions_rds_management" {
  name        = "github-actions-rds-management"
  description = "Allow GitHubActionsRole to manage RDS instances via Terraform (strict RDS-only)"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # RDS actions that MUST use "*"
      {
        Sid    = "AllowRDSCreateModifyDeleteDescribe",
        Effect = "Allow",
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
          "rds:DescribeDBEngineVersions",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeDBSecurityGroups",
          "iam:CreateServiceLinkedRole",
          "iam:GetServiceLinkedRoleDeletionStatus",
          "rds:DescribeDBParameterGroups"
        ],
        Resource = "*"
      },

      # RDS actions that CAN be scoped to resource ARNs
      {
        Sid    = "AllowRDSTagging",
        Effect = "Allow",
        Action = [
          "rds:AddTagsToResource",
          "rds:ListTagsForResource"
        ],
        Resource = "arn:aws:rds:::*"
      }
    ]
  })
}

data "aws_iam_role" "github_actions_role" {
  name = "GithubActionsRole"
}

resource "aws_iam_role_policy_attachment" "github_actions_rds_management_attach" {
  role       = data.aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_rds_management.arn
}

# Subnet group for RDS (private subnets only)
resource "aws_db_subnet_group" "newsdb_subnet_group" {
  name       = "${var.env}-rds-newsdb-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  tags = {
    Name = "${var.env}-newsdb-subnet-group"
  }
}

resource "aws_db_instance" "newsdb" {
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  identifier        = "${var.env}-news-db"
  username          = var.db_user
  password          = var.db_password
  allocated_storage = 20

  db_subnet_group_name     = aws_db_subnet_group.newsdb_subnet_group.name
  publicly_accessible = false
  skip_final_snapshot = true
  vpc_security_group_ids = [var.rds_sg_id]
  depends_on = [ aws_iam_role_policy_attachment.github_actions_rds_management_attach ]
}
