# CLAUDE.md — homelab-infra (Terraform multi-cloud) navigator

## What this is

Terraform-managed cloud infrastructure for the homelab, spanning multiple providers.
**OVH first, then Cloudflare, AWS later.** This repo previously held an OCI free-tier
setup (compute + self-hosted runners); that has been removed in favour of OVH/Cloudflare.

This is the **infra** sibling to the `homelab` repo (k3s + ArgoCD GitOps). Keep them
separate: cluster workloads live in `homelab`, cloud/provider infrastructure lives here.

## Repo layout

Each provider is its own flat Terraform **root module** with its own backend + state —
the same shape the old `oci/` module had. This isolates blast radius per `apply`.

- `ovh/`        — OVH root module (first provider being built)
- `cloudflare/` — Cloudflare root module (planned)
- `aws/`        — AWS root module (later)
- `modules/`    — shared reusable modules, if/when extraction is worth it (create on demand)
- `.github/workflows/` — per-provider plan/apply pipelines
- `docs/agent-notes/`  — scope-specific living notes (read before topic work)

## Hard conventions (don't deviate without asking)

- **One root module = one provider = one state file.** Don't cross providers in a single
  module or `apply`. Cloudflare DNS that points at an OVH host still lives in `cloudflare/`.
- **Pin every provider version** in `<provider>/versions.tf` with `~>`. No floating versions.
- **No secrets in `.tfvars`, variables, or anything state-readable.** Provider credentials
  come from GitHub Actions secrets / env (the OCI setup used `TF_VAR_*` + repo secrets — keep
  that pattern). Prefer OIDC over long-lived keys where the provider supports it (AWS does).
- **`terraform fmt` + `validate` must pass before commit.** Add `tflint` / `trivy` as the
  repo grows.
- **Agents never run `terraform apply` / `destroy`** (denied in `.claude/settings.json`).
  Produce the plan; the human applies. Same spirit as the `git push` deny — the agent goes
  right up to the irreversible step and stops.

## How CI works here

The removed OCI workflow established the pattern, mirror it per provider:
- **Plan on PR**, **apply on push to `main`**, both path-filtered to that provider's dir
  (`paths: ["ovh/**"]`) so unrelated changes don't trigger it.
- Credentials via repo secrets as `TF_VAR_*` env. For AWS, switch to GitHub OIDC
  (`AssumeRoleWithWebIdentity`) instead of static keys.
- Consider a scheduled `plan -detailed-exitcode` drift check that opens an issue on drift.

## Scope notes — read before starting topic work

`docs/agent-notes/` holds per-scope living docs that capture decisions (with **why**),
partial state, and gotchas from previous sessions. `scope-map.json` maps scope → repo
paths and is the source of truth for which scope a file belongs to.

**Protocol:**
1. Identify the scope of the request (usually a provider: `ovh`, `cloudflare`, `aws`, or `ci`).
2. If `docs/agent-notes/<scope>.md` exists, **read it first**. Trust its "Verified as of"
   line; re-verify with `git log` if stale.
3. If it doesn't exist and the work is non-trivial, **create it** from the template in
   `docs/agent-notes/README.md` and add it to that README's Index.
4. **Update it** before ending: Decisions taken (+why), Open questions, Recent changes log;
   bump "Verified as of" to today + current `git rev-parse --short HEAD`.

A Stop hook (`.claude/hooks/scope-notes-reminder.py`, wired in `.claude/settings.json`)
reminds once if the session edited a scope's files without touching its note. It fails open
and blocks at most once per session — stop again if the edit was trivial.

**Adding a new scope** (e.g. `tf-foundation` for a shared state-backend bootstrap, or
`secrets`): pick a kebab-case name, add it to `scope-map.json` with **disjoint** path
patterns, create `<scope>.md`, and list it in the README Index. Keep patterns disjoint — the
hook fires every matching scope, so overlaps produce double reminders.

## Onboarding a new provider / resource — checklist

Before writing Terraform, **ask the user** about:
1. Which provider and is this a new root module or an addition to an existing one?
2. Remote state backend for it (where state + locking live).
3. New credentials / OIDC trust needed, and how CI gets them.
4. Whether it needs DNS records (likely the `cloudflare/` scope) or cross-provider wiring.

Then: create/extend `<provider>/`, pin providers in `versions.tf`, wire a path-filtered
workflow under `.github/workflows/`, and update the scope note.

## Key pointers

- `docs/agent-notes/` — scope-specific living notes (one file per provider/topic)
- `docs/agent-notes/README.md` — scope-notes protocol + template
- `docs/agent-notes/scope-map.json` — scope → path map (source of truth)
- `.claude/settings.json` — hook wiring + apply/push deny guardrails
