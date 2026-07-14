# Cloudflare

**Status:** live — merged to main (PR #6, `58ce4e6`); state adopted; CI plan+apply green
**Verified as of:** 2026-07-14 on commit `58ce4e6`
**Owner of scope (in repo):** `cloudflare/dns/`, `cloudflare/tunnel/`

## What this covers
All Cloudflare control-plane objects for BOTH homelab and mojerodos (the user is fine keeping
them together in this repo): zones, zone settings, persistent DNS records, the Cloudflare
Tunnel object + its public-hostname/ingress config, and API tokens. Does NOT cover in-cluster
workloads that merely *consume* Cloudflare (the cloudflared connector, cert-manager, Traefik) —
those live in the sibling `homelab` repo (k3s + ArgoCD GitOps). See the split table below.

## The homelab/ArgoCD boundary (verified 2026-07-13)

Enumerated all 50 ArgoCD Applications in `homelab/argocd/` and grepped the whole cluster.
**There is no external-dns, no DNS-record operator, no Cloudflare operator anywhere.** Only
two ArgoCD apps reach the Cloudflare control plane at all:

1. **cert-manager** (`infra-cert-manager` + `-config`) — dynamically creates/deletes
   **`_acme-challenge.*` TXT records** via a `Zone:DNS:Edit` API token, on every DNS-01
   challenge (~every 60 days per cert). This is the ONLY thing ArgoCD writes into Cloudflare
   DNS, and it is ephemeral.
2. **cloudflared** (`infra-cloudflared`) — runs the tunnel **connector only** (data plane).
   Reads a `TUNNEL_TOKEN` secret, makes outbound connections. Manages NO tunnel config and NO
   DNS records — the tunnel is remote-managed, so its public hostnames live in the dashboard.

Everything else (`app-*`, mojerodos dev/prod app-of-apps, monitoring, storage) is in-cluster
workloads with HTTPRoutes; **none touch Cloudflare.**

Consequence: **every persistent DNS record is hand-made in the dashboard** (there is no
external-dns to conflict with). So importing them into Terraform collides with nothing.

## Split — what Terraform manages here vs. what stays k8s (homelab)

| Category                                   | Manager today                | Verdict                                              |
|--------------------------------------------|------------------------------|------------------------------------------------------|
| Zones, zone settings                       | dashboard (by hand)          | → Terraform (import)                                 |
| All persistent DNS records (apex/CNAME/MX/TXT) | dashboard (by hand)      | → Terraform (import) — no ArgoCD conflict            |
| Tunnel object + public-hostname config     | dashboard (by hand)          | → Terraform (import)                                 |
| API tokens (cert-mgr, tunnel)              | dashboard; value in SOPS     | → Terraform *shape*, secret handoff stays manual     |
| `_acme-challenge.*` TXT records            | **cert-manager (ArgoCD)**    | → **stays k8s — never import / declare**             |
| cloudflared connector, Certificates, Issuers | ArgoCD (runtime)           | → stays k8s (not Cloudflare-API objects)             |

**Hard rule this imposes:** any root managing a zone's records must use **per-record resources**
(`cloudflare_dns_record`), never an authoritative "delete anything not in TF" mode — because
cert-manager keeps injecting transient `_acme-challenge` TXTs that Terraform must not know
about. The per-record resource is naturally safe; just don't declare or import the challenge
records.

## Zones / domains in play (all created by hand)

| Zone           | Purpose                                                              | Origin repo        |
|----------------|---------------------------------------------------------------------|--------------------|
| `miveal.eu`    | Homelab. `lan.miveal.eu` is LAN-only (not externally reachable)      | homelab            |
| `wroher.eu`    | Homelab external — `vault/photos/books/home.wroher.eu` via Tunnel    | homelab            |
| `mojerodos.pl` | Real public site (RODO product), served via cluster                 | homelab app / mojerodos |
| `bobr.pro`     | Real public, served via Tunnel                                      | homelab            |

The tunnel is **remote-managed** (cloudflared runs with `TUNNEL_TOKEN`, no local `config.yaml`),
so 100% of its public-hostname → service mapping is dashboard click-ops today.

## Key files
- `cloudflare/README.md` — operator runbook (the split + the one-off import/adopt procedure).
- `cloudflare/dns/` — root: `zones.tf` (4 zones + `local.account_id`), `records.tf` (26 static
  records, `zone_id = cloudflare_zone.<z>.id`), `imports.tf` (30 import blocks — delete after
  first apply), `versions.tf` (backend `cloudflare/dns/…`, provider `~> 5.22`), `providers.tf`,
  `variables.tf`.
- `cloudflare/tunnel/` — root: `tunnel.tf` (the `homelab` tunnel + its ingress config),
  `records.tf` (9 tunnel CNAMEs, `zone_id = local.zone_ids[...]`), `locals.tf` (account_id +
  zone-id map), `imports.tf` (11 blocks), plus the same versions/providers/variables trio.
- `.github/workflows/cloudflare.yml` — changed-leaf matrix (plan on PR, apply on `main`/prod).
- `.github/workflows/_terraform.yml` — extended with an optional `cloudflare_api_token` secret →
  `TF_VAR_cloudflare_api_token` (see [[ci]]).

## Conventions specific to this scope
- **Provider = `cloudflare/cloudflare ~> 5.22`** (5.22.0 pinned; lock files carry linux_amd64 +
  darwin_arm64). v5 is a full OpenAPI-generated rewrite — schema differs sharply from v4 AND from
  what the registry/GitHub docs render. Verified live: `cloudflare_zone` uses `name` +
  `account = { id = ... }` (NOT `zone =` / `account_id =`); `cloudflare_dns_record` replaces v4's
  `cloudflare_record`; the tunnel config uses `config = { ingress = [ { hostname, service,
  origin_request = {...} } ] }` attribute syntax (NOT v4 `ingress_rule {}` blocks). **Do not
  hand-write against remembered/registry v4 schema — generate against the real provider.**
- **Never** manage `_acme-challenge.*` TXT records (cert-manager owns them — see boundary above).
- Use per-record `cloudflare_dns_record`, not a zone-authoritative pattern.
- No secrets in state (repo-wide convention). Terraform may own the *shape* of API tokens and
  the tunnel, but the token/connector-secret VALUE handoff to k8s stays manual/SOPS. Do not add
  `cloudflare_api_token` resources whose secret value would land in state without the user
  explicitly accepting that exception.
- State lives in the shared `mojerodos-tfstate` S3 bucket (from `aws/bootstrap`), keyed
  `cloudflare/<component>/<env>/terraform.tfstate` per repo convention.
- Cloudflare has no OIDC federation; CI credential is a scoped API token in a GitHub repo
  secret passed as `TF_VAR_*` / `CLOUDFLARE_API_TOKEN` (per CLAUDE.md non-AWS provider rule).

## Decisions taken (2026-07-14)
- **Tunnel scope → TF owns tunnel object + ingress rules + matching CNAMEs.** Moves the biggest
  click-ops pile into code. The connector token VALUE stays a manual SOPS handoff to k8s — TF
  owns the shape, not the secret. (No `cloudflare_api_token`/token-secret resources in state.)
- **Module split → per-component: `cloudflare/dns/` + `cloudflare/tunnel/`.** Two roots, two
  state files, matching the `aws/` per-component pattern. A tunnel change can't blast DNS. The
  tunnel's CNAMEs live in `cloudflare/tunnel/` (1:1 with its ingress rules — don't split them
  into `dns/`); `cloudflare/dns/` owns zones, settings, and all *static* records.
- **CI creds → scoped Cloudflare API token in a GitHub repo secret, passed as `TF_VAR_*` /
  `CLOUDFLARE_API_TOKEN`.** Per CLAUDE.md non-AWS-provider rule. State stays in the shared
  `mojerodos-tfstate` S3 bucket via scoped AWS creds.
- **Env layer → account-global (no env sub-dir), like `aws/billing`.** Zones/DNS are account
  singletons. Any `dev.mojerodos.pl`-style records are just more records in the same zone, not a
  separate per-env root.

## How the config was produced (repeatable)
Live IDs + config were pulled with a **read-scoped** token via `import {}` blocks +
`terraform plan -generate-config-out` against v5.22 (read-only; no apply). Then curated
(dropped null/computed attrs) and re-verified: **dns = 30 import / 0 change**, **tunnel =
11 import / 1 change** (the 1 = benign computed re-PUT). Full account inventory (IDs) was
captured to the session scratchpad `cf_dns_records.json` during the session.

## Open questions / pending decisions
- **Done & live.** Both roots adopted + merged to main; CI `plan (dns)`, `plan (tunnel)` green on
  PR #6 and the prod-gated apply-on-merge succeeded. `CLOUDFLARE_API_TOKEN` repo secret is set.
- **Zone settings not yet managed** (SSL/TLS mode, Always-HTTPS, min TLS, etc.). Only zones +
  records + tunnel are imported. Add `cloudflare_zone_setting` (or the v5 equivalent) later if
  wanted — pull current values the same generate-config-out way.
- **`lan.miveal.eu` / `mojadzialka.miveal.eu` / `wroher.eu` apex** are public **proxied A records
  → `79.110.199.171`** (an OVH VPS IP). Noted as-is; `lan.*` being LAN-only in homelab docs yet
  having a public proxied A record is worth a sanity check with the user, but it was imported
  faithfully, not changed.

## Recent changes log
- 2026-07-14 (`58ce4e6`, PR #6 squash-merged): **merged + CI-verified live.** `plan (dns)` and
  `plan (tunnel)` green on the PR; prod-gated apply-on-merge for both roots succeeded (dns no-op;
  tunnel = the one benign computed `version` re-PUT). Cloudflare is now fully TF-managed on main.
  (Same push also re-ran the AWS billing apply via the shared `_terraform.yml` — it failed on a
  pre-existing anomaly-monitor limit, unrelated to CF; see [[aws]].)
- 2026-07-14 (`feat/cloudflare-import`): **state adopted** — user ran the first import-apply for
  both roots against the shared S3 backend and deleted the `imports.tf` blocks; created the
  `CLOUDFLARE_API_TOKEN` repo secret. The CI-maintenance work turned out to be already squash-merged
  to main (PR #4 / `a2366d9`), so this was rebased to a clean Cloudflare-only branch off main.
- 2026-07-14 (`2481c88`, working tree): **scaffolded + import-verified both roots.** Pulled the
  live account (4 zones, 35 records, 1 tunnel `homelab` + its 10-rule ingress) via a read-scoped
  token; generated schema-correct v5.22 config with `-generate-config-out`; curated + verified
  zero-drift (dns 30/0, tunnel 11/1-benign). Wrote `cloudflare/{dns,tunnel}/` + `README.md`,
  wired `cloudflare.yml` + extended `_terraform.yml` with the CF token secret, committed lock
  files. Not applied — state adoption is the human's next step.
- 2026-07-14 (`2481c88`): locked the three design decisions (tunnel+ingress+CNAMEs in TF,
  per-component `dns/`+`tunnel/` split, API token via repo secret / `TF_VAR_*`, account-global
  no-env-layer). Recorded under "Decisions taken". Still no `.tf` written — next step is
  scaffolding the two roots + gathering live import IDs.
- 2026-07-13 (`2481c88`): scope created. Verified the homelab/ArgoCD boundary (no external-dns;
  only cert-manager + cloudflared touch Cloudflare, cert-manager only via ephemeral challenge
  TXTs). Documented the import/keep split and the four zones. No Terraform written yet.

## Gotchas
- **Tunnel CNAMEs are auto-created** by Cloudflare when a public hostname is added to a
  remote-managed tunnel; they are 1:1 with the tunnel ingress rules. If TF owns the tunnel
  ingress config it should also own those CNAMEs — don't split them across roots.
- **cert-manager will race Terraform on the same zones** via `_acme-challenge` TXTs. Harmless
  with per-record resources, but a `terraform plan` run mid-challenge may momentarily show a
  transient TXT that isn't in code — ignore it, never import it.
- The cert-manager API token is `Zone:DNS:Edit` scoped (per `homelab/secrets/cloudflare-api-token.yaml`
  header). If TF ever manages token scopes, match that exactly or cert-manager breaks.
- **`cloudflare_zero_trust_tunnel_cloudflared_config` always shows "1 to change" after import** —
  `version`/`created_at`/`source` are server-computed, so the first apply re-PUTs the (identical)
  ingress and bumps `version`. Not a routing change. Don't chase it.
- **`origin_request` is a partial object** — omitting an optional field means "unset/default".
  `vault.wroher.eu` has `no_tls_verify = false` set *explicitly* live, so it must be set explicitly
  in config or plan shows a spurious `false -> null`. All other rules only set `origin_server_name`
  (+ `http_host_header` on `dev-472980`). The catch-all `{ service = "http_status:404" }` MUST stay
  the last ingress element.
- **Resource labels are load-bearing**: `imports.tf` `to = cloudflare_dns_record.<label>` must match
  the resource label exactly (they were generated from the same key = `type_name_id6`). Renaming a
  resource without updating its import block breaks adoption.
