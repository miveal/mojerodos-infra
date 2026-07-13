terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42"
    }
  }

  # Central state bucket lives in eu-central-1; these billing resources live in us-east-1.
  # Backend region != provider region — that's expected.
  backend "s3" {
    bucket       = "mojerodos-tfstate"
    key          = "aws/billing/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
