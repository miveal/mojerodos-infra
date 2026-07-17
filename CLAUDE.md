# CLAUDE.md — mojerodos-infra (Terraform multi-cloud) navigator

## What this is

Terraform-managed cloud infrastructure for **MojeRODos** (a GDPR/RODO product), spanning
multiple cloud providers. **AWS is live first** (serverless foundation: central Terraform
state, billing; Bedrock next); OVH and Cloudflare follow. This repo previously held a
personal homelab OCI free-tier setup; that was removed.

This is the cloud-**infra** repo. The MojeRODos **application** runs on the `homelab` k3s
cluster (sibling repo: k3s + ArgoCD GitOps, Cloudflare DNS) and *consumes* the AWS services
provisioned here (Bedrock — planned) as an external caller (via IAM Roles Anywhere — planned).
Keep them separate: cluster workloads live in `homelab`, cloud/provider infra lives here.
**SMS is deliberately NOT on AWS** (no PL brand protection, no Terraform surface) — it's an
app-level SMSAPI.pl integration in the `homelab` repo. See [[aws]] for the why.

## Repo layout

Each provider is a directory of **per-component × per-env root modules**, each with its own
backend + state — small blast radius per `apply`. Account-global plumbing (state backend,
CI identity, billing, the SMS sender ID) is a single root that skips the env layer.

- `aws/`        — AWS (live). `bootstrap/` (manual: OIDC + CI role + central state bucket),
                  `billing/`, `identity/<env>/` (app principals, grants, EU-residency boundary);
                  `bedrock/` (service-side: guardrails + invocation logging), `network/`, `rds/` planned.
- `ovh/`        — OVH root module(s) (planned) — will use the AWS S3 bucket as its state backend
- `cloudflare/` — Cloudflare root module (planned; DNS)
- `<provider>/modules/` — shared child modules, created ONLY when a real multi-call composite emerges
- `.github/workflows/`  — CI: reusable `_terraform.yml` + per-provider changed-leaf matrix
- `docs/agent-notes/`   — scope-specific living notes (read before topic work)

**Central state:** the S3 bucket from `aws/bootstrap` (`mojerodos-tfstate`) holds Terraform
state for ALL providers, keyed `<provider>/<component>/<env>/terraform.tfstate`. So
`aws/bootstrap` must be applied before any other provider (incl. OVH) can `init`.

## Hard conventions (don't deviate without asking)

- **One root module = one component × env = one state file.** Small blast radius per `apply`.
  Don't cross providers in a single module/apply. Account-global plumbing (bootstrap, billing,
  sms) is a single root with no env sub-dir; per-env workloads use `<component>/<env>/`.
- **Public modules, called directly from flat roots.** Prefer registry modules
  (`terraform-aws-modules/*`) to offload maintenance. Do NOT wrap them in a pass-through module —
  write a `<provider>/modules/<x>/` composite only when the SAME multi-resource composition is
  reused (rule of three), and keep nesting ≤2 deep (HashiCorp flat-composition guidance).
  Cross-component references use **tag/name data-source lookups**, not `terraform_remote_state`.
- **Pin every provider version** in `versions.tf` with `~>`. No floating versions. (AWS `~> 6.42`.)
- **Naming:** `<project>-<env>-<component>[-<detail>]`, lowercase-kebab; project = `mojerodos`;
  short code `mrd` only where a length cap forces it.
- **Tagging:** provider `default_tags` = Project / Environment / Component / ManagedBy /
  Repository; per-resource `Name`, plus `DataClassification` on data-storing resources. (No
  `Owner` tag while the product is solo — re-add if ownership ever splits. If a root ever uses
  the `awscc` provider, note it has no `default_tags` — tag those resources explicitly.)
- **No secrets in `.tfvars`, variables, or anything state-readable.** Credentials come from CI:
  AWS via **GitHub OIDC** (`AssumeRoleWithWebIdentity`, role `mojerodos-cicd-deploy`); other
  providers via repo secrets as `TF_VAR_*`.
- **EU data residency (RODO):** keep resources in EU regions; for Bedrock use only the `eu.`
  geographic inference profile, never `Global`. Standalone account (no Org/SCP) → enforce via
  IAM permission boundary.
- **`terraform fmt` + `validate` must pass before commit.** Add `tflint` / `trivy` as the
  repo grows.
- **Agents never run `terraform apply` / `destroy`** (denied in `.claude/settings.json`).
  Produce the plan; the human applies. Same spirit as the `git push` deny — the agent goes
  right up to the irreversible step and stops.
- **`main` is never committed to directly — all changes land via a merged PR.** Work on a
  feature branch, open a PR, let CI plan, merge to apply. If a commit ends up on local `main`,
  move it to a branch (`git switch -c <branch>` then `git branch -f main origin/main`) before
  pushing. CI enforces this shape: plan on PR, apply on push to `main` (= a merge).

## How CI works here

- A reusable `_terraform.yml` (fmt/init/validate + plan|apply for one leaf) plus per-provider
  callers (`aws.yml`) that **detect changed leaves** and fan out a matrix.
- **Plan on PR, apply on push to `main`**, path-filtered (`aws/**`, excluding `aws/bootstrap/**`).
- AWS auth is **GitHub OIDC** — assumes `mojerodos-cicd-deploy` (ARN in repo variable
  `AWS_DEPLOY_ROLE_ARN`). Applies are gated behind the **`prod` GitHub Environment** (manual
  approval); its subject `environment:prod` is what the role trusts, alongside `pull_request`.
- Other providers (OVH) will get credentials via repo secrets as `TF_VAR_*`, plus scoped AWS
  creds for the shared S3 state backend.
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
