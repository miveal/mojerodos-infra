terraform {
  # 1.10+ required for S3-native state locking (use_lockfile) in the aws/ root module.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42"
    }
    # Used by the iam-oidc-provider module to fetch the GitHub OIDC thumbprint.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # State migrated from local into the bucket this module itself created (chicken-and-egg:
  # applied once with local state, then migrated). Same central bucket as every other root,
  # keyed by provider/component; account-global plumbing so no env segment.
  backend "s3" {
    bucket       = "mojerodos-tfstate"
    key          = "aws/bootstrap/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
