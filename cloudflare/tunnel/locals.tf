# Cloudflare zone IDs (stable, non-secret). Kept as literals here rather than a
# data-source lookup or a cross-state ref into cloudflare/dns/ — the two roots stay
# decoupled (no terraform_remote_state). If a zone is ever recreated, update the id.
locals {
  account_id = "545b7d8d7ec133775292d024a9097899"
  zone_ids = {
    "bobr.pro"     = "d820cd379144c08158eff447c77afad2"
    "mojerodos.pl" = "de00ff89d6cb5c0540330bd8fc498781"
    "wroher.eu"    = "71f082d9d88d7aa068dfbb87876aa713"
  }
}
