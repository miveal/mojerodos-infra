output "app_user_name" {
  description = "IAM user the dev app authenticates as. Mint its access key manually (see README) — never via Terraform."
  value       = aws_iam_user.app.name
}

output "app_user_arn" {
  description = "ARN of the dev app IAM user."
  value       = aws_iam_user.app.arn
}

output "invoke_policy_arn" {
  description = "EU-only Bedrock invocation policy attached to the app user (also serves as its permissions boundary)."
  value       = aws_iam_policy.invoke_eu.arn
}
