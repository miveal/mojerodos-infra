output "cicd_deploy_role_arn" {
  description = "ARN of the GitHub Actions OIDC deploy role. Set as the GitHub Actions repo variable AWS_DEPLOY_ROLE_ARN."
  value       = module.cicd_deploy_role.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC identity provider."
  value       = module.github_oidc_provider.arn
}

output "state_bucket_name" {
  description = "Central S3 bucket holding Terraform state for all infra. Matches the backend blocks in every root module."
  value       = module.state_bucket.s3_bucket_id
}
