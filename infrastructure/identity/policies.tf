resource "aws_iam_policy" "github_actions_ec2_readonly" {
  name        = "github-actions-ec2"
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
          "ec2:CreateVpc",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeAddressesAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:*"
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
          "rds:CreateDBSubnetGroup",
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
          "rds:ListTagsForResource",
          "rds:ModifyDBSubnetGroup",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DetachNetworkInterface",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "arn:aws:rds:*:*:*"
      },
      {
        "Sid" : "AllowENIManagementForTerraform",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DetachNetworkInterface",
          "ec2:DeleteNetworkInterface"
        ],
        "Resource" : "*"
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
