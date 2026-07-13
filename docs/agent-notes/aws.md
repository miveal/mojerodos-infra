# AWS

**Status:** partial — `bootstrap` APPLIED + state in S3; `billing` built, not applied
**Verified as of:** 2026-07-13 on commit `f882ef0` (working tree; aws/ still uncommitted)
**Owner of scope (in repo):** `aws/` (`bootstrap/`, `billing/`, …)

## What this covers
All AWS Terraform. AWS is the MojeRODos **serverless foundation + shared services** account:
central Terraform state (for all providers, OVH included), billing/cost controls, Bedrock
(planned). Not a compute host yet. Does NOT cover Cloudflare DNS ([[cloudflare]]), the homelab
app, or **SMS** (moved off AWS → SMSAPI.pl, app-side; see the SMS decision below). CI wiring is
shared with [[ci]].

## Current state
- **`aws/bootstrap/`** — **APPLIED** 2026-07-13 (account `474939505073`, user `miveal`). GitHub
  OIDC provider, CI deploy role `mojerodos-cicd-deploy` (trust: `pull_request` + `environment:prod`),
  central state bucket `mojerodos-tfstate` (versioned, AES256, TLS-only, S3-native locking).
  **State migrated local→S3** (`aws/bootstrap/terraform.tfstate`, `use_lockfile`); `plan` clean,
  no drift. Local `terraform.tfstate` now empty + `.backup` retained (both git-ignored).
  Role ARN is `arn:aws:iam::474939505073:role/mojerodos-cicd-deploy-*` (has a random suffix from
  the iam-role module — read exact value from `terraform output -raw cicd_deploy_role_arn`).
- **`aws/billing/`** (us-east-1 provider) — monthly cost budget ($20, alerts→`dariusz89k@gmail.com`),
  Cost Anomaly Detection (immediate, ≥$5 impact), cost-allocation-tag activation for our tag keys.
  No `Owner` tag (dropped while solo); billing `alert_email` is notification-only, not a tag.
- `.github/workflows/aws.yml` + `_terraform.yml` — changed-leaf matrix, OIDC, prod approval gate.
- Both roots pass `terraform validate` (via a temp TF 1.10.5 binary — see gotcha). Cross-
  platform `.terraform.lock.hcl` committed (linux_amd64 + darwin).

## Decisions taken (with why)
- **Repo → `mojerodos-infra`; product slug `mojerodos`.** `miveal/…` is provenance only (OIDC
  trust sub + `Repository` tag), never in resource names. See naming/tagging in CLAUDE.md.
- **Per-component × per-env roots, flat, public modules called directly** (no wrapper layer —
  wrapper/deep-nesting is an anti-pattern; extract a composite only at rule-of-three). Account-
  global plumbing (bootstrap/billing) skips the env dir.
- **Central `mojerodos-tfstate` bucket backs ALL providers** (OVH too), keyed by provider —
  so bootstrap gates every other `init`. Name is brand-distinctive (global-unique) so backend
  blocks avoid an account-id suffix.
- **S3-native locking (needs TF ≥1.10; user upgrading), no DynamoDB.** Pins: aws `~> 6.42`
  (s3-bucket module floor), tls `~> 4.0`.
- **Standalone account (no Org)** → EU-residency guardrails go on IAM permission boundaries, not SCPs.
- **App auth = IAM Roles Anywhere** (homelab is NAT'd, outbound-only) — PARKED until the app is ready.
- **SMS is NOT on AWS.** PL sender IDs are dynamic (non-exclusive) and AWS can't hold Poland's
  statutory sender-ID protection (integrator-bound; AWS isn't a UKE-listed integrator), so AWS
  gives zero brand/anti-phishing protection. There's also no Terraform surface for SMS providers.
  **Decision: SMS → SMSAPI.pl** (LINK Mobility Poland; best RODO/DPA + human sender-name
  verification + OAuth2 OTP API + Go SDK; SerwerSMS/Vercom as backup), implemented **app-side in
  the `homelab` repo** (API key = k8s secret). Real brand protection = trademark + aggregator
  sender-name whitelisting + reporting impersonation to CSIRT NASK. The `aws/sms/` component was
  built then removed once this became clear.

## Parked (planned, deliberately NOT scaffolded yet)
- `identity/` — IAM Roles Anywhere (trust anchor = homelab CA), `mojerodos-app` role, EU-residency
  permission boundary. Build when the app starts calling AWS.
- `bedrock/` — guardrails + invocation logging + app policy; MUST use the `eu.` inference profile
  only (ban `Global`), whitelist models by retention behaviour (Claude Fable 5 / GPT-5.x retain ~30d).
- `network/` + `rds/` — VPC only when RDS/compute lands. `eu-central-1-waw-1a` Local Zone stays
  reserved/unused (regional services don't touch it).

## Manual runbook (non-IaC, has lead time)
1. Apply `aws/bootstrap` (admin creds). 2. `gh variable set AWS_DEPLOY_ROLE_ARN …`. 3. Create the
`prod` GitHub Environment w/ required reviewer. 4. Bedrock (when built): Anthropic one-time usage form.

## Open questions / pending decisions
- ~~Whether to migrate `aws/bootstrap` state local→S3~~ DONE 2026-07-13 (backend block added,
  `init -migrate-state -force-copy`, verified no-drift).
- Cost-allocation-tag activation may fail on a brand-new account until tag keys are discovered
  (~24h after first tagged resource exists) — may need a billing re-apply. See gotcha.
- Repo rename to `mojerodos-infra`: CONFIRMED done on GitHub (`homelab-infra` now redirects to
  `mojerodos-infra`). Local `git remote` still points at the old `homelab-infra` SSH URL — needs
  `git remote set-url origin git@github.com:miveal/mojerodos-infra.git` (redirect keeps it working
  meanwhile). Attempted 2026-07-11 but the harness auto-denied the change (user hadn't named it).

## Recent changes log
- 2026-07-13 (`f882ef0`, wt): Applied `aws/bootstrap` (human, admin creds); added `backend "s3"`
  to bootstrap `versions.tf` and migrated state local→S3 (`init -migrate-state -force-copy`).
  `plan` clean. Terraform now 1.15.8 locally (was 1.6.5). GitHub repo rename confirmed. Still
  uncommitted; billing not yet applied.
- 2026-07-11 (`f882ef0`): AWS onboarding built — bootstrap rewritten to mojerodos convention;
  `billing/` component; changed-leaf-matrix CI w/ prod approval gate; flat placeholder `aws/*.tf`
  root removed. Naming/tagging/module conventions folded into CLAUDE.md. Nothing applied.
- 2026-07-11 (`f882ef0`): dropped the `Owner` tag (solo product); billing `alert_email` →
  `dariusz89k@gmail.com`, notification-only. Removed `aws/sms/` after concluding SMS belongs on
  SMSAPI.pl app-side, not AWS (see SMS decision) — this also dropped the only `awscc` usage.

## Gotchas
- **Local `terraform` is 1.6.5** — too old to `init` (`>= 1.10` required). Validated with a
  throwaway 1.10.5 binary; user must upgrade before running bootstrap.
- Backend blocks can't interpolate — bucket/region hardcoded in every `versions.tf`; keep in sync.
- **Billing lives in us-east-1** (global service control-plane) even though the state bucket is
  eu-central-1: backend region ≠ provider region, intentional.
- **`aws_ce_cost_allocation_tag` discovery lag:** activating a tag key errors until AWS has seen
  it on a resource (~24h). First billing apply on the empty account may need a re-run.
- Don't rebuild `aws/sms/` — SMS is intentionally off AWS (see SMS decision). PL sender IDs are
  dynamic/non-exclusive and AWS can't hold Polish statutory protection.
