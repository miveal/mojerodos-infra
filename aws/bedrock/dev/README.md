# aws/bedrock/dev — dev-app Bedrock invocation slice

The minimal slice of the (parked) `bedrock/` component that unblocks the first live caller:
the MojeRODos dev backend's Ogrodniczy advisor chat (hub epic agent#887 Wave B, core v1.59.0).

**Creates:** an invocation-only IAM policy (EU inference profiles + underlying foundation
models, `aws:RequestedRegion eu-*` residency condition), the same document attached as a
**permissions boundary**, and the static-key IAM user `mojerodos-dev-bedrock` the k3s dev app
authenticates as.

**Deliberately NOT here** (still parked, per `docs/agent-notes/aws.md`):

- `identity/` — IAM Roles Anywhere is the planned successor for app auth (homelab is
  NAT'd/outbound-only). It needs a homelab-side CA + cert plumbing, so this root ships a
  static-key user as an explicit stopgap. When `identity/` lands, the app user here is
  retired.
- Bedrock guardrails + model-invocation logging — the rest of the parked `bedrock/`
  component; follow-up work, not needed for first traffic (the app has its own budget
  freeze at $30/day / $300/month and writes an `ai_audit_log` row per call).

## Apply

Via the normal repo flow: PR → CI `plan` → merge → prod-gated `apply`. No local apply.

## Post-apply manual steps (human, has lead time)

1. **Bedrock model access** (console, eu-central-1 → *Model access*): enable
   **Amazon Nova Lite** (grounded chat turns) + **Anthropic Claude Haiku 4.5** (ungrounded
   turns — carries most Wave B traffic). Enable Claude Sonnet 4.6 + Opus 4.6 while there
   (bound for later waves; free until invoked). Anthropic requires a one-time use-case form.
2. **Mint the access key** (never via Terraform — keeps the secret out of state):
   `aws iam create-access-key --user-name mojerodos-dev-bedrock` (or console → user →
   Security credentials).
3. **Deliver to the cluster** (homelab repo, sops-encrypted Secret; ArgoCD applies it and
   the Deployment's `envFrom` injects it):

   ```bash
   cd ~/rod_project/homelab
   sops set secrets/mojerodos-app-secrets.yaml '["stringData"]["AWS_ACCESS_KEY_ID"]' '"AKIA…"'
   sops set secrets/mojerodos-app-secrets.yaml '["stringData"]["AWS_SECRET_ACCESS_KEY"]' '"…"'
   git add secrets/mojerodos-app-secrets.yaml && git commit -m "feat(mojerodos-dev): Bedrock credentials" && git push
   ```

## Cost context

App-side spend control already exists (freeze-breaker $30/day / $300/month; per-user token
quota). The account-wide budget in `aws/billing` is **$20/month** — with Bedrock traffic
starting, its alerts will fire early by design; raising it is a human/billing decision, not
part of this root.
