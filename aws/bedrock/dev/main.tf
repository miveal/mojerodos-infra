locals {
  tags = {
    Project     = "mojerodos"
    Environment = "dev"
    Component   = "bedrock"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
  }
}

# Invocation-only grant for the dev app (Ogrodniczy advisor chat, agent#887 Wave B).
# The Converse / ConverseStream APIs authorize as bedrock:InvokeModel(+WithResponseStream).
# Cross-region inference: a call on an eu.* geographic inference profile authorizes against
# BOTH the profile ARN and the underlying per-region foundation-model ARNs — both stanzas
# are required or CRIS calls fail with AccessDenied.
# aws:RequestedRegion eu-* is the RODO data-residency guardrail: standalone account, no
# Org/SCP available, so EU-only is enforced at the principal (here + the boundary below).
data "aws_iam_policy_document" "invoke_eu" {
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

resource "aws_iam_policy" "invoke_eu" {
  name   = "mojerodos-dev-bedrock-invoke"
  policy = data.aws_iam_policy_document.invoke_eu.json

  tags = { Name = "mojerodos-dev-bedrock-invoke" }
}

# Permissions boundary = hard ceiling for this principal: even if a broader policy is
# ever attached to the user later, effective permissions stay capped at EU-only Bedrock
# invocation. Same document as the grant on purpose — grant ∩ boundary = the grant.
resource "aws_iam_policy" "boundary" {
  name   = "mojerodos-dev-bedrock-boundary"
  policy = data.aws_iam_policy_document.invoke_eu.json

  tags = { Name = "mojerodos-dev-bedrock-boundary" }
}

# Static-key programmatic user for the k3s dev app — STOPGAP until identity/
# (IAM Roles Anywhere) is built; the homelab cluster is NAT'd/outbound-only, so no
# instance/pod role is possible. The access key is minted MANUALLY (see README) so the
# secret never enters Terraform state; it reaches the cluster via the sops-encrypted
# Secret in the homelab repo.
resource "aws_iam_user" "app" {
  name                 = "mojerodos-dev-bedrock"
  permissions_boundary = aws_iam_policy.boundary.arn

  tags = { Name = "mojerodos-dev-bedrock" }
}

resource "aws_iam_user_policy_attachment" "app_invoke" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.invoke_eu.arn
}
