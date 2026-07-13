variable "aws_region" {
  description = "AWS region for the state backend and default provider. Parent region of the eu-central-1-waw-1a Local Zone."
  type        = string
  default     = "eu-central-1"
}

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to assume the CI/CD deploy role via OIDC."
  type        = string
  default     = "miveal/mojerodos-infra"
}

variable "prod_environment" {
  description = "GitHub Actions Environment used to gate prod applies. The role's OIDC trust allows this environment's subject."
  type        = string
  default     = "prod"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket holding Terraform state for ALL infra (AWS + OVH), keyed by provider/component/env. MUST match the backend blocks in every root module."
  type        = string
  default     = "mojerodos-tfstate"
}

variable "deploy_role_name" {
  description = "Name of the IAM role GitHub Actions assumes for plan/apply."
  type        = string
  default     = "mojerodos-cicd-deploy"
}
