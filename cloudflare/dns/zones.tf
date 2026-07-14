# Cloudflare zones. All four sit under one account (Dariusz89k's Account).
# Imported from the dashboard; see imports.tf. account.id is not secret.
locals {
  account_id = "545b7d8d7ec133775292d024a9097899"
}

resource "cloudflare_zone" "bobr_pro" {
  account = { id = local.account_id }
  name    = "bobr.pro"
  type    = "full"
}

resource "cloudflare_zone" "miveal_eu" {
  account = { id = local.account_id }
  name    = "miveal.eu"
  type    = "full"
}

resource "cloudflare_zone" "mojerodos_pl" {
  account = { id = local.account_id }
  name    = "mojerodos.pl"
  type    = "full"
}

resource "cloudflare_zone" "wroher_eu" {
  account = { id = local.account_id }
  name    = "wroher.eu"
  type    = "full"
}
