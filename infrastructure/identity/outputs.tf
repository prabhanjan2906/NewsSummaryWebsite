output "is_identity_deployed" {
  value = (aws_iam_role_policy_attachment.github_actions_ec2_readonly_attach.id != null) && (aws_iam_role_policy_attachment.lambda_vpc_policy_attach.id != null) ? 1 : 0
}