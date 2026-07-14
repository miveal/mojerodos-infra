# cloudflare/ — Cloudflare zones, DNS, and the homelab tunnel

Terraform for the Cloudflare control plane shared by **homelab** and **mojerodos**. Two
independent root modules (each its own S3-backed state), split by blast radius:

| Root                | Manages                                                                 |
|---------------------|-------------------------------------------------------------------------|
| [`dns/`](dns/)      | The 4 zones + their static DNS records (apex, MX, SPF/DKIM/DMARC, OVH mail, verification) |
| [`tunnel/`](tunnel/)| The `homelab` Cloudflare Tunnel object, its public-hostname ingress config, and the 9 tunnel CNAMEs |

Zones: `bobr.pro`, `miveal.eu`, `mojerodos.pl`, `wroher.eu` — all under one account.

## The k8s boundary (do NOT manage here)

- **`_acme-challenge.*` TXT records** are created/deleted dynamically by **cert-manager**
  in the `homelab` cluster. They are never imported or declared here. `cloudflare_dns_record`
  is per-record, so cert-manager and Terraform coexist without fighting.
- The **cloudflared connector** (the pod) and its **token** live in `homelab`. This repo owns
  the tunnel's *shape* (ingress rules), not the connector secret — `tunnel_secret` is
  deliberately omitted (`config_src = "cloudflare"`), so no secret lands in state.

See [`docs/agent-notes/cloudflare.md`](../docs/agent-notes/cloudflare.md) for the full split + rationale.

## Credentials

- **Cloudflare provider:** a scoped API token, supplied as `TF_VAR_cloudflare_api_token`
  (GitHub repo secret `CLOUDFLARE_API_TOKEN` in CI; `export TF_VAR_cloudflare_api_token=…`
  locally). Never committed. `dns/` needs Zone + DNS edit; `tunnel/` needs Account · Cloudflare
  Tunnel + Zone · DNS edit.
- **State backend:** the shared `mojerodos-tfstate` S3 bucket, via AWS OIDC in CI.

## First-time state adoption (one-off)

Every resource here was created by hand in the dashboard, so the first apply **imports**
existing objects — it does not create anything. `imports.tf` in each root holds the
`import {}` blocks, verified to import with zero drift (the `tunnel/` config resource shows a
single benign in-place update: its server-computed `version`/`created_at`, not a routing change).

```sh
export TF_VAR_cloudflare_api_token=<token with edit scope>
cd cloudflare/dns      # then repeat for cloudflare/tunnel
terraform init
terraform plan         # expect "N to import, 0 to add, 0 to change, 0 to destroy" (tunnel: 1 to change)
terraform apply        # adopts the resources into state
```

After a root's apply succeeds, **delete that root's `imports.tf`** — import blocks are inert
once the resources are in state. In CI this apply runs on merge to `main`, gated by the `prod`
GitHub Environment.
