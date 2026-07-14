variable "cloudflare_api_token" {
  description = "Cloudflare API token (Account:Cloudflare Tunnel:Edit, Zone:DNS:Edit). Supplied as TF_VAR_cloudflare_api_token from a GitHub repo secret in CI, or exported locally. Never committed."
  type        = string
  sensitive   = true
}
