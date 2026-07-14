# CI

**Status:** partial
**Verified as of:** 2026-07-14 on commit `58ce4e6` (cloudflare.yml live + green)
**Owner of scope (in repo):** `.github/workflows/`

## What this covers
The GitHub Actions pipelines that plan/apply each provider's Terraform, and cross-cutting CI
conventions. Provider-specific resource decisions live in that provider's note ([[aws]], [[ovh]]).

## Current state
- **`_terraform.yml`** — reusable (`workflow_call`): fmt→init→validate→plan|apply for one leaf
  (root module). Inputs: `working_directory`, `apply` (bool), `environment` (gate). OIDC auth for
  the S3 backend + an **optional `cloudflare_api_token` secret** → job env `TF_VAR_cloudflare_api_token`
  (empty for AWS leaves, which don't init the CF provider; set for `cloudflare/` leaves).
- **`aws.yml`** — caller. `detect` job diffs changed files → JSON list of changed leaves (any
  `aws/*` dir with an S3 backend, excluding `bootstrap`); `plan` matrix on PRs; `apply` matrix
  on push to `main`, `max-parallel: 1`, gated behind the **`prod` Environment** (manual approval).
- **`cloudflare.yml`** — caller, same shape as `aws.yml` (changed-leaf matrix over `cloudflare/*`
  S3-backed dirs; no `bootstrap` to exclude). Passes `secrets.CLOUDFLARE_API_TOKEN` through.
  **VALIDATED LIVE 2026-07-14 on PR #6:** `plan (dns)` + `plan (tunnel)` green, apply-on-merge
  green. Proves the CF-token-secret path + shared S3 backend (AWS OIDC) end-to-end. See [[cloudflare]].
- **VALIDATED LIVE 2026-07-13** on PR #3: `detect` → `plan (billing)` passed green — OIDC role
  assumption + S3 backend init + plan all work end-to-end; `apply` correctly skipped on the PR.
- **`main` is branch-protected** (GitHub): PR required before merge, `enforce_admins: true` (even
  the owner can't push direct), force-push + deletion blocked, 0 required approvals (solo repo —
  GitHub blocks self-approval; owner merges manually). Agent `git push` allowed in settings.json
  (direct-to-main is stopped server-side, not by a client deny).
- Cloudflare workflow added (`cloudflare.yml`), not yet live; no OVH workflow yet.

## Key files
- `.github/workflows/_terraform.yml` — the shared plan/apply implementation
- `.github/workflows/aws.yml` — AWS changed-leaf matrix (see [[aws]] for the role + backend)
- `.github/workflows/cloudflare.yml` — Cloudflare changed-leaf matrix (see [[cloudflare]])

## Conventions specific to this scope (mirror per new provider)
- **One reusable workflow, thin per-provider callers.** A caller detects changed leaves and
  fans out a matrix into `_terraform.yml`. Don't duplicate the terraform steps per provider.
- **Plan on PR, apply on push to `main`**, `paths:`-filtered to the provider dir, excluding any
  manual `bootstrap/` (`!aws/bootstrap/**`).
- **AWS uses OIDC** (`id-token: write` + `role-to-assume` from repo variable `AWS_DEPLOY_ROLE_ARN`).
  Applies run inside the **`prod` GitHub Environment** (approval gate) → their OIDC subject is
  `environment:prod`, which the role's trust must allow (plans use `pull_request`). For OVH/CF,
  credentials come from repo **secrets** as `TF_VAR_*` (no OIDC path) + scoped AWS creds for the S3 backend.
- Pin action versions (major moving tags) and Terraform (`TF_VERSION`, `1.10.5`; must be ≥ 1.10).
  Current: `actions/checkout@v7`, `aws-actions/configure-aws-credentials@v6`,
  `hashicorp/setup-terraform@v4` (bumped 2026-07-13 off the Node20-deprecated majors).
- **Dependabot** (`.github/dependabot.yml`) watches `terraform` (module + provider constraints
  under `/aws/**`) and `github-actions` (workflow `uses:`), weekly, grouped, PRs labelled
  `dependencies`. Its PRs run the normal plan CI and merge through the same gate.
- `concurrency` per ref, `cancel-in-progress: false` — never interrupt an apply.

## Open questions / pending decisions
- Apply ordering: `max-parallel: 1` serializes, but the matrix order isn't a real DAG. Fine while
  leaves are independent; add explicit ordering when `network` → `compute`/`rds` deps appear.
- Per-leaf Environment approval means one approval click per changed component on `main` — acceptable, revisit if noisy.
- Scheduled `plan -detailed-exitcode` drift check that opens an issue (CLAUDE.md suggests; not built).
- Posting the PR plan as a comment (workflow logs it today).

## Recent changes log
- 2026-07-14 (`58ce4e6`, PR #6): added `cloudflare.yml` + extended `_terraform.yml` with the
  optional `cloudflare_api_token` secret. Ran green live (plan + apply). **Side effect:** because
  the PR edited the shared `_terraform.yml`, `aws.yml` re-ran ALL aws leaves on merge → the billing
  `apply` fired on main and **failed on a pre-existing anomaly-monitor limit** (not CF-related; see
  [[aws]]). Editing `_terraform.yml` will always re-trigger every provider's leaves.
- 2026-07-13 (PR #4): bumped actions to latest majors (checkout v7, configure-aws-credentials v6,
  setup-terraform v4) resolving the Node20 warning; added `.github/dependabot.yml` (terraform +
  github-actions). Also root `.gitignore` + billing cost-allocation-tag apply fix (see [[aws]]).
- 2026-07-13 (PR #3): first live CI run — `plan (billing)` green through OIDC → proved
  bootstrap + deploy role + S3 backend end-to-end. Enabled `main` branch protection (PR-only,
  enforce_admins). Moved `git push` from settings deny → allow. Node20-deprecation warning on
  `checkout@v4`/`configure-aws-credentials@v4`/`setup-terraform@v3` (non-blocking; bump later).
- 2026-07-11 (`f882ef0`): reworked AWS CI from a single flat job into `_terraform.yml` (reusable)
  + `aws.yml` (changed-leaf matrix) with the `prod` Environment approval gate. Established the
  reusable-workflow pattern for future providers.

## Gotchas
- `detect` needs `fetch-depth: 0` for the base-vs-head diff; it falls back to `HEAD~1` if the base
  sha is missing (new branch / zero sha).
- Empty matrix is guarded (`needs.detect.outputs.leaves != '[]'`) so no leaves → jobs skip.
- A change to the workflow files themselves re-runs ALL leaves (intentional).
- CI `init` for a leaf needs the S3 bucket + deploy role to exist (from `aws/bootstrap`) and
  `AWS_DEPLOY_ROLE_ARN` set — fails until onboarding is done. Expected on a fresh repo.
