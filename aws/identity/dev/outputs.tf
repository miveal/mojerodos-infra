output "app_user_name" {
  description = "IAM user the dev app authenticates as. Mint its access key manually (see README) — never via Terraform."
  value       = aws_iam_user.app.name
}

output "app_user_arn" {
  description = "ARN of the dev app IAM user."
  value       = aws_iam_user.app.arn
}

output "app_boundary_policy_arn" {
  description = "EU-residency permissions boundary applied to the dev app principal."
  value       = aws_iam_policy.app_boundary.arn
}

output "bedrock_invoke_policy_arn" {
  description = "EU-only Bedrock invocation policy attached to the dev app user."
  value       = aws_iam_policy.bedrock_invoke_eu.arn
}
