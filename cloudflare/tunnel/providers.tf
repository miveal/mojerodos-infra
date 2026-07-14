# Cloudflare has no OIDC federation, so auth is a scoped API token supplied out-of-band:
# in CI, a GitHub repo secret exposed as TF_VAR_cloudflare_api_token; locally, exported
# the same way. Never committed, never in .tfvars. See CLAUDE.md (non-AWS provider creds).
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
