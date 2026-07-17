locals {
  tags = {
    Project     = "mojerodos"
    Environment = "dev"
    Component   = "identity"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
  }
}

# Bedrock invocation grant for the dev app principal (first caller: Ogrodniczy advisor
# chat, agent#887 Wave B).
# The Converse / ConverseStream APIs authorize as bedrock:InvokeModel(+WithResponseStream).
# Cross-region inference: a call on an eu.* geographic inference profile authorizes against
# BOTH the profile ARN and the underlying per-region foundation-model ARNs — both stanzas
# are required or CRIS calls fail with AccessDenied.
# aws:RequestedRegion eu-* is the RODO data-residency guardrail: standalone account, no
# Org/SCP available, so EU-only is enforced at the principal (here + the boundary below).
data "aws_iam_policy_document" "bedrock_invoke_eu" {
  statement {
    sid = "InvokeEUProfilesOnly"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]

    resources = [
      "arn:aws:bedrock:*:*:inference-profile/eu.*",
      "arn:aws:bedrock:*::foundation-model/*",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:RequestedRegion"
      values   = ["eu-*"]
    }
  }
}

resource "aws_iam_policy" "bedrock_invoke_eu" {
  name   = "mojerodos-dev-app-bedrock-invoke"
  policy = data.aws_iam_policy_document.bedrock_invoke_eu.json

  tags = { Name = "mojerodos-dev-app-bedrock-invoke" }
}

# EU-residency permissions boundary — the hard ceiling for every principal in this root
# (the planned Roles Anywhere role included, not just today's user). Even if a broader
# policy is attached later, effective permissions stay capped at EU-only Bedrock
# invocation. Same document as the grant today on purpose — grant ∩ boundary = the grant;
# they diverge as soon as the app needs a non-Bedrock service, at which point the boundary
# widens by service but keeps the eu-* region condition.
resource "aws_iam_policy" "app_boundary" {
  name   = "mojerodos-dev-app-boundary"
  policy = data.aws_iam_policy_document.bedrock_invoke_eu.json

  tags = { Name = "mojerodos-dev-app-boundary" }
}

# Static-key programmatic user for the k3s dev app — STOPGAP until this root grows the
# planned IAM Roles Anywhere path (trust anchor = homelab CA); the homelab cluster is
# NAT'd/outbound-only, so no instance/pod role is possible. The access key is minted
# MANUALLY (see README) so the secret never enters Terraform state; it reaches the cluster
# via the sops-encrypted Secret in the homelab repo.
resource "aws_iam_user" "app" {
  name                 = "mojerodos-dev-app"
  permissions_boundary = aws_iam_policy.app_boundary.arn

  tags = { Name = "mojerodos-dev-app" }
}

resource "aws_iam_user_policy_attachment" "app_bedrock_invoke" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.bedrock_invoke_eu.arn
}
