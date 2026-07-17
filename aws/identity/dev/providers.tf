# IAM is a global service; eu-central-1 is the account home region and the
# Bedrock source region the app is configured for (homelab BEDROCK_REGION).
provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = local.tags
  }
}
