# OVH

**Status:** planned
**Verified as of:** 2026-06-08 on commit `87a5a89`
**Owner of scope (in repo):** `ovh/` (Terraform root module — to be created)

## What this covers
All OVH Terraform: the `ovh/` root module and any OVH-specific shared modules. Provider
auth, state backend for OVH, compute/network/storage resources. Does NOT cover Cloudflare
DNS that points at OVH hosts — that's the [[cloudflare]] scope.

## Current state
- Nothing live yet. OVH is the first provider being built out in this repo (replacing the
  removed OCI free-tier setup).

## Key files
- `ovh/` — root module (backend.tf, providers.tf, versions.tf, *.tf) — not yet created

## Conventions specific to this scope
- Pin the OVH provider version in `ovh/versions.tf` with `~>`.
- OVH API credentials (application key/secret/consumer key) come from GitHub Actions
  secrets / env — never commit them to `.tfvars` or state-readable inputs.
- One root module = one provider = one state file. Don't reach into Cloudflare/AWS from here.

## Open questions / pending decisions
- Remote state backend choice for OVH (OVH Object Storage S3-compatible? Terraform Cloud?).
- Whether self-hosted runners get rebuilt on OVH (the OCI version was removed).

## Recent changes log
- 2026-06-08 (`87a5a89`): scope created; OCI removed from the repo; OVH chosen as first
  provider. No OVH Terraform written yet.

## Gotchas
- (none yet — record OVH provider/API surprises here as they come up)
