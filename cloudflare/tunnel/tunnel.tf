# The "homelab" Cloudflare Tunnel — remotely managed (config_src = "cloudflare"),
# so its public-hostname routing lives here in Terraform rather than the dashboard.
#
# The connector token is NOT managed here: config_src = "cloudflare" means the token
# is issued by Cloudflare and handed to the cloudflared Deployment in the homelab repo
# as a SOPS-encrypted k8s Secret. Terraform owns the tunnel's SHAPE, not the secret —
# tunnel_secret is deliberately omitted (would otherwise land a secret in state).
resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id = local.account_id
  name       = "homelab"
  config_src = "cloudflare"
}

# Public-hostname ingress. Every rule proxies to Traefik in-cluster (which routes by
# Host). Order matters: the catch-all http_status:404 MUST stay last.
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = local.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab.id

  config = {
    ingress = [
      {
        hostname = "vault.wroher.eu"
        service  = "https://traefik.traefik.svc:443"
        origin_request = {
          origin_server_name = "vault.wroher.eu"
          no_tls_verify      = false
        }
      },
      {
        hostname       = "mojerodos.pl"
        service        = "https://traefik.traefik.svc:443"
        origin_request = { origin_server_name = "mojerodos.pl" }
      },
      {
        hostname       = "www.mojerodos.pl"
        service        = "https://traefik.traefik.svc:443"
        origin_request = { origin_server_name = "www.mojerodos.pl" }
      },
      {
        hostname       = "photos.wroher.eu"
        service        = "https://traefik.traefik.svc:443"
        origin_request = { origin_server_name = "photos.wroher.eu" }
      },
      {
        hostname       = "books.wroher.eu"
        service        = "https://traefik.traefik.svc:443"
        origin_request = { origin_server_name = "books.wroher.eu" }
      },
      {
        hostname       = "ha.wroher.eu"
        service        = "https://traefik.traefik.svc:443"
        origin_request = { origin_server_name = "ha.wroher.eu" }
      },
      {
        hostname = "dev-472980.mojerodos.pl"
        service  = "https://traefik.traefik.svc:443"
        origin_request = {
          http_host_header   = "dev-472980.mojerodos.pl"
          origin_server_name = "dev-472980.mojerodos.pl"
        }
      },
      {
        hostname       = "bobr.pro"
        service        = "https://traefik.traefik.svc:443"
        origin_request = { origin_server_name = "bobr.pro" }
      },
      {
        hostname       = "www.bobr.pro"
        service        = "https://traefik.traefik.svc:443"
        origin_request = { origin_server_name = "www.bobr.pro" }
      },
      {
        service = "http_status:404"
      },
    ]
  }
}
