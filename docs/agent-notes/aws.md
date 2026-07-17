# AWS

**Status:** partial — `bootstrap` APPLIED; `billing` APPLIED (green 2026-07-14); `bedrock/dev` BUILT, not applied (PR pending)
**Verified as of:** 2026-07-17 on commit `6365548` + `aws/bedrock/dev` on PR branch `feat/aws-bedrock-dev-app-access`
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
  **First apply (PR #3 merge) FAILED** on the cost-allocation-tag discovery lag (see gotcha):
  budget applied; anomaly monitor + tag activation did not. **Fixed** by gating activation behind
  `activate_cost_allocation_tags` (bool, default `false`) — first apply skips it; flip `true` in a
  follow-up apply once keys are discovered (>24h). Re-apply after that fix creates the anomaly
  monitor + subscription too.
- **`aws/bedrock/dev/`** — BUILT 2026-07-17 (PR branch `feat/aws-bedrock-dev-app-access`), not
  applied. Minimal dev-app slice of the parked `bedrock/` component: EU-only invocation policy
  (`eu.*` inference profiles + foundation models, `aws:RequestedRegion eu-*` condition), same
  document attached as permissions boundary, static-key user `mojerodos-dev-bedrock` (key minted
  manually — never in TF state; delivered via homelab sops Secret). First consumer: Ogrodniczy
  advisor chat (hub agent#887 Wave B, core v1.59.0). Guardrails + invocation logging + Roles
  Anywhere deliberately NOT in scope (see Parked). `validate` green; lock committed
  (linux_amd64 + darwin_arm64).
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
- **Static-key user for dev Bedrock access = explicit STOPGAP (2026-07-17).** The `identity/`
  Roles-Anywhere trigger ("build when the app starts calling AWS") HAS fired — Wave B advisor
  chat (core v1.59.0) is the first live caller — but RA needs homelab-side CA/cert plumbing
  (novel infra, own PR). Chosen instead: least-privilege static-key user, EU-only enforced
  twice (policy condition AND permissions boundary), key minted manually so the secret never
  enters TF state, delivered via the homelab sops Secret. Retire the user when `identity/` lands.
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
  permission boundary. Trigger ("build when the app starts calling AWS") FIRED 2026-07-17 —
  bridged by the `bedrock/dev` static-key stopgap; RA build itself still parked pending homelab
  CA plumbing.
- `bedrock/` — guardrails + invocation logging (the app-policy slice SHIPPED via `bedrock/dev`,
  2026-07-17); MUST use the `eu.` inference profile only (ban `Global`), whitelist models by
  retention behaviour (Claude Fable 5 / GPT-5.x retain ~30d).
- `network/` + `rds/` — VPC only when RDS/compute lands. `eu-central-1-waw-1a` Local Zone stays
  reserved/unused (regional services don't touch it).

## Manual runbook (non-IaC, has lead time)
1. Apply `aws/bootstrap` (admin creds). 2. `gh variable set AWS_DEPLOY_ROLE_ARN …`. 3. Create the
`prod` GitHub Environment w/ required reviewer. 4. Bedrock (when built): Anthropic one-time usage form.

## Open questions / pending decisions
- ~~Whether to migrate `aws/bootstrap` state local→S3~~ DONE 2026-07-13 (backend block added,
  `init -migrate-state -force-copy`, verified no-drift).
- **Re-enable cost-allocation tags:** set `activate_cost_allocation_tags = true` (billing) and
  re-apply once >24h have passed since bootstrap's tagged resources existed (bootstrap applied
  2026-07-13, so on/after ~2026-07-14). Until then it stays `false` or the apply fails.
- Repo rename to `mojerodos-infra`: CONFIRMED done on GitHub (`homelab-infra` now redirects to
  `mojerodos-infra`). Local `git remote` still points at the old `homelab-infra` SSH URL — needs
  `git remote set-url origin git@github.com:miveal/mojerodos-infra.git` (redirect keeps it working
  meanwhile). Attempted 2026-07-11 but the harness auto-denied the change (user hadn't named it).

## Recent changes log
- 2026-07-17 (PR branch `feat/aws-bedrock-dev-app-access`): built `aws/bedrock/dev` — EU-only
  invocation policy + permissions boundary + static-key user `mojerodos-dev-bedrock` for the
  first live app caller (Ogrodniczy advisor chat, agent#887 Wave B / core v1.59.0). `validate`
  green, lock committed (linux_amd64 + darwin_arm64). NOT applied. Post-apply manual: Bedrock
  model access (Nova Lite + Claude Haiku 4.5 minimum; Sonnet 4.6 + Opus 4.6 prep) + key mint
  (`aws iam create-access-key`) + homelab sops Secret. Deviation from parked plan (static key
  vs Roles Anywhere) flagged in the PR for human ratification.
- 2026-07-14: **billing apply FIXED** (two AWS constraints, both surfaced when Cloudflare PR #6
  re-ran the aws matrix). (1) The DIMENSIONAL/SERVICE anomaly-monitor limit — AWS auto-creates a
  `Default-Services-Monitor` that occupies the one allowed slot; adopted it via
  `terraform import aws_ce_anomaly_monitor.service <default-monitor-arn>` (renames in-place to
  `mojerodos-service-monitor`). (2) `frequency = "IMMEDIATE"` + EMAIL is invalid → switched to
  `DAILY` (PR #9). Billing `apply` now green (budget + adopted monitor + DAILY subscription).
- 2026-07-13 (PR #4): billing apply failed on cost-allocation-tag discovery lag → gated
  activation behind `activate_cost_allocation_tags` (default false). Bumped CI actions to latest
  majors, added root `.gitignore` (folded in `aws/.gitignore`) and Dependabot (terraform + actions).
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
- ~~Local `terraform` is 1.6.5 — too old to `init`~~ RESOLVED: local is 1.14.8 as of 2026-07-17
  (`bedrock/dev` validated with it directly; CI still pins 1.10.5 in `_terraform.yml`).
- Backend blocks can't interpolate — bucket/region hardcoded in every `versions.tf`; keep in sync.
- **Billing lives in us-east-1** (global service control-plane) even though the state bucket is
  eu-central-1: backend region ≠ provider region, intentional.
- **`aws_ce_cost_allocation_tag` discovery lag:** activating a tag key errors until AWS has seen
  it on a resource (~24h). First billing apply on the empty account may need a re-run.
- **Cost Anomaly Detection has two AWS constraints (both hit + resolved 2026-07-14):**
  (1) **One DIMENSIONAL/SERVICE monitor per account** — AWS auto-creates a `Default-Services-Monitor`
  that fills the slot, so creating `aws_ce_anomaly_monitor.service` errors `Limit exceeded on
  dimensional spend monitor creation`. Resolution: adopt the default via `terraform import
  aws_ce_anomaly_monitor.service <arn>` (find it with `aws ce get-anomaly-monitors --region
  us-east-1`); it renames in-place to `mojerodos-service-monitor`. (2) **`frequency = "IMMEDIATE"`
  requires an SNS-topic subscriber** — EMAIL subscribers only work with `DAILY`/`WEEKLY`
  (`Immediate frequencies only support SNSTopic subscriptions`). We use `DAILY` + email (no SNS,
  like the budget). Both were surfaced by CF PRs re-triggering the aws matrix — **not CF-related**.
- Don't rebuild `aws/sms/` — SMS is intentionally off AWS (see SMS decision). PL sender IDs are
  dynamic/non-exclusive and AWS can't hold Polish statutory protection.
