resource "aws_iam_policy" "github_actions_ec2_readonly" {
  name        = "github-actions-ec2-readonly"
  description = "Allow GitHubActionsRole to call EC2 Describe APIs needed by Terraform VPC module"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowEC2DescribeForTerraform",
        Effect = "Allow",
        Action = [
          "ec2:AllocateAddress",
          "ec2:CreateTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNatGateways",
          "ec2:DescribeAddresses",
          "ec2:CreateVpc"
        ],
        Resource = "*"
      },

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

resource "aws_iam_role_policy_attachment" "github_actions_ec2_readonly_attach" {
  role       = data.aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_ec2_readonly.arn
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

# 1. VPC
resource "aws_vpc" "news_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "news-vpc"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

# 2. Internet Gateway for public subnets
resource "aws_internet_gateway" "news_igw" {
  vpc_id = aws_vpc.news_vpc.id

  tags = {
    Name = "news-igw"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

# 3. Public subnets (for NAT gateway, ALBs, etc.)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.news_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "news-public-a"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.news_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "news-public-b"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

# 4. Private subnets (for RDS + Lambdas)
resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.news_vpc.id
  cidr_block = "10.0.11.0/24"

  tags = {
    Name = "news-private-a"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.news_vpc.id
  cidr_block = "10.0.12.0/24"

  tags = {
    Name = "news-private-b"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

# 5. Public route table (0.0.0.0/0 -> IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.news_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.news_igw.id
  }

  tags = {
    Name = "news-public-rt"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

# 6. NAT Gateway in public subnet A
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "news-nat-eip"
  }
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

resource "aws_nat_gateway" "news_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "news-nat"
  }

  depends_on = [aws_eip.nat_eip, aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

# 7. Private route table (0.0.0.0/0 -> NAT)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.news_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.news_nat.id
  }

  tags = {
    Name = "news-private-rt"
  }
  depends_on = [aws_internet_gateway.news_igw, aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
  depends_on = [aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach]
}

output "private_subnet_a_id" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_b.id
}
