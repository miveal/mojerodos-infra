locals {
  tags = {
    Project     = "mojerodos"
    Environment = "shared" # account-global plumbing, not env-specific
    Component   = "bootstrap"
    ManagedBy   = "terraform"
    Repository  = var.github_repo
  }

  # OIDC subjects allowed to assume the deploy role. Exact match (StringEquals):
  #   - plan on pull_request         -> repo:<repo>:pull_request
  #   - apply gated by Environment   -> repo:<repo>:environment:prod
  # Applies run inside the GitHub Environment (manual approval), so their token
  # subject is environment:<env>, NOT ref:refs/heads/main.
  oidc_subjects = [
    "${var.github_repo}:pull_request",
    "${var.github_repo}:environment:${var.prod_environment}",
  ]
}

# GitHub Actions OIDC identity provider. One per AWS account; every deploy role trusts it.
module "github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "~> 6.6"

  url = "https://token.actions.githubusercontent.com"

  tags = local.tags
}

# CI/CD deploy role assumed by GitHub Actions via OIDC.
# AdministratorAccess to start; tighten to least-privilege once the resource set stabilises.
module "cicd_deploy_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.6"

  name        = var.deploy_role_name
  description = "GitHub Actions OIDC role for mojerodos-infra plan/apply (repo ${var.github_repo})."

  enable_github_oidc = true
  oidc_subjects      = local.oidc_subjects

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  max_session_duration = 3600

  tags = local.tags

  # The trust policy references the provider ARN by construction, so order creation explicitly.
  depends_on = [module.github_oidc_provider]
}

# Central Terraform state bucket for ALL infra (AWS + OVH), keyed by provider/component/env.
# S3-native locking (no DynamoDB). tfstate can contain secrets -> DataClassification=sensitive.
module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.14"

  bucket = var.state_bucket_name

  # Block all public access.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Retain state history, encrypt at rest, deny non-TLS access.
  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = true

  tags = merge(local.tags, {
    Name               = var.state_bucket_name
    DataClassification = "sensitive"
  })
}
