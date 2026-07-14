# Tunnel CNAMEs — each hostname the "homelab" tunnel serves resolves to
# <tunnel-id>.cfargotunnel.com. 1:1 with the ingress rules in tunnel.tf.
# Auto-created by Cloudflare when a public hostname is added; adopted here.

resource "cloudflare_dns_record" "cname_bobr_pro_58321d" {
  zone_id = local.zone_ids["bobr.pro"]
  name    = "bobr.pro"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_www_bobr_pro_4ff10f" {
  zone_id = local.zone_ids["bobr.pro"]
  name    = "www.bobr.pro"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_dev_472980_mojerodos_pl_6a8ab5" {
  zone_id = local.zone_ids["mojerodos.pl"]
  name    = "dev-472980.mojerodos.pl"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_mojerodos_pl_24138b" {
  zone_id = local.zone_ids["mojerodos.pl"]
  name    = "mojerodos.pl"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_www_mojerodos_pl_b0060e" {
  zone_id = local.zone_ids["mojerodos.pl"]
  name    = "www.mojerodos.pl"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_books_wroher_eu_f0d9ee" {
  zone_id = local.zone_ids["wroher.eu"]
  name    = "books.wroher.eu"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_ha_wroher_eu_4e3d8b" {
  zone_id = local.zone_ids["wroher.eu"]
  name    = "ha.wroher.eu"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_photos_wroher_eu_9370c2" {
  zone_id = local.zone_ids["wroher.eu"]
  name    = "photos.wroher.eu"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "cname_vault_wroher_eu_75ddeb" {
  zone_id = local.zone_ids["wroher.eu"]
  name    = "vault.wroher.eu"
  type    = "CNAME"
  content = "cbbd687a-a90d-41d6-bde5-305bc25bb946.cfargotunnel.com"
  ttl     = 1
  proxied = true
}
