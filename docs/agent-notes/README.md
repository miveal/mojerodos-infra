# Agent notes — scope-specific working docs

This directory holds **scope-specific living docs** that future agent sessions read before doing work in that scope, and update at the end of the session. Each file is the running brain-state for one topic (usually a cloud provider: `ovh`, `cloudflare`, `aws`, or a cross-cutting topic like `ci`).

These are agent-facing notes, not human runbooks. They prioritise "what does the agent need to know to be useful immediately" over polished prose. They are allowed to be terse, opinionated, and slightly messy.

## Index

- [OVH](ovh.md) — OVH Terraform root module; first provider being built (replaces removed OCI setup)
- [AWS](aws.md) — AWS Terraform root module + one-time `aws/bootstrap/` onboarding (GitHub OIDC, CI deploy role, S3 state backend)
- [CI](ci.md) — GitHub Actions plan/apply pipelines and cross-cutting CI conventions (per-provider workflows)

<!--
When adding a new note, list it here as:
- [Topic](topic.md) — one-line description of scope
-->

## Scope map

Scope name → repo-relative path patterns lives in [scope-map.json](scope-map.json). This is the **source of truth** for both humans (deciding which scope new work belongs to) and the Stop hook ([.claude/hooks/scope-notes-reminder.py](../../.claude/hooks/scope-notes-reminder.py)) which uses it to detect "you touched files under scope X but didn't update X.md".

When introducing a new scope:
1. Pick a kebab-case name.
2. Add it to `scope-map.json` with the path patterns that belong to it.
3. Create `<scope>.md` from the template.
4. Add a line to the **Index** above.

Patterns ending with `/` are directory prefixes; others are `fnmatch` globs (`*.tf`, `*/backend.tf`). Keep patterns **disjoint** across scopes — the hook fires every matching scope, so overlaps produce double reminders.

## Automated reminder (Stop hook)

`.claude/hooks/scope-notes-reminder.py` runs on the Stop event. If the session edited files under a scope in `scope-map.json` and didn't also touch `docs/agent-notes/<scope>.md`, it blocks Stop once with a reminder. The block fires at most once per session (`stop_hook_active` short-circuits the second pass), and any error in the hook fails open. You can override by simply stopping again after the reminder if the edit was trivial.

## Protocol — how agents use this directory

Before any non-trivial session that fits an identifiable scope (a provider like `ovh` / `cloudflare` / `aws`, or a cross-cutting topic like `ci` / `tf-foundation` / `secrets`):

1. **Pick the scope.** From the user's request, identify the closest topic. If it doesn't fit any existing file, pick a kebab-case name (e.g. `rate-limiting`, `external-exposure`).
2. **Read the file if it exists.** `docs/agent-notes/<scope>.md`. Trust the **Status** and **Verified as of** lines — if the file is older than the recent git log for the relevant code paths, verify before relying on it.
3. **Add it to the Index** in this README if the file is new.
4. **Do the work** (with the file's context loaded into your reasoning).
5. **Update the file before ending the session.** Capture:
   - Anything you discovered that wasn't in the file
   - Decisions taken in the session (with the **why**)
   - New open questions
   - Update **Verified as of** to today's date and the current `git rev-parse --short HEAD`
   - If a section is now wrong, fix it — don't add a contradicting note alongside

If the scope is trivial (typo, one-line tweak, rename), skip the protocol — these files are for non-trivial work.

## Template

When creating a new scope file, copy this skeleton:

```markdown
# <Scope title>

**Status:** live | partial | planned | aspirational
**Verified as of:** YYYY-MM-DD on commit `<short SHA>`
**Owner of scope (in repo):** <paths, e.g. `ovh/`, `modules/cloudflare-dns/`>

## What this covers
One paragraph: what falls inside this scope and what doesn't.

## Current state
Bullet list: what is actually implemented and applied today (cite files).
Mark anything that is planned/aspirational and not yet live.

## Key files
- `path/to/main.tf` — what it provisions
- `path/to/variables.tf` — what it configures

## Conventions specific to this scope
Anything an agent should follow that isn't in `CLAUDE.md`.

## Open questions / pending decisions
Track unresolved choices the user hasn't decided. One bullet each, with context.

## Recent changes log
- YYYY-MM-DD (`<short SHA>`): what changed in this session, why
- YYYY-MM-DD (`<short SHA>`): ...

## Gotchas
Surprises encountered. Things that would mislead a fresh agent reading the code cold.
```

## What NOT to put here

- Polished human docs — that's `CLAUDE.md` and any future `docs/` runbooks.
- Generic Terraform / cloud-provider background — agents know that already.
- Anything that duplicates `CLAUDE.md`.
- Long lists of files that `grep`/`ls` would surface in seconds.
- Secrets, tokens, credentials, OCIDs/IDs not already in the repo.

## What this is _for_

- Capturing the **why** behind decisions that took deliberation but aren't obvious from the resulting `.tf`.
- Recording **partial implementations** ("network module exists but no compute yet — decided to wait until X").
- Flagging **gotchas** another agent would hit (e.g. "this provider's `apply` is non-idempotent on resource Y", "free-tier limit caps this at N").
- Keeping a **timeline** of what each session touched, so the next session can pick up the thread.
