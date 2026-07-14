terraform {
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.22"
    }
  }

  # State in the shared bucket from aws/bootstrap. Backend auth is AWS (OIDC in CI);
  # the Cloudflare provider auth is a separate API token (see providers.tf).
  backend "s3" {
    bucket       = "mojerodos-tfstate"
    key          = "cloudflare/dns/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
