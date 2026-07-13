# aws/bootstrap — one-time MojeRODos AWS onboarding

Creates the pieces that must exist **before** CI can run Terraform, so it is applied
**locally, once, by a human** with admin credentials (agents can't `apply`). Everything
after this is OIDC + CI-driven; no static AWS keys in GitHub.

It provisions:

1. **GitHub Actions OIDC provider** (`token.actions.githubusercontent.com`) — one per account.
2. **CI/CD deploy role** (`mojerodos-cicd-deploy`) — trusts `miveal/mojerodos-infra` via OIDC,
   scoped to `pull_request` (plan) and `environment:prod` (gated apply). `AdministratorAccess`
   for now; tighten later.
3. **Central state bucket** (`mojerodos-tfstate`) — versioned, encrypted, TLS-only. Holds
   Terraform state for **all** infra (AWS + OVH), keyed `<provider>/<component>/<env>`, with
   **S3-native locking** (no DynamoDB).

## Prerequisites

- **Terraform ≥ 1.10** (`terraform version`) — required for `use_lockfile`. Upgrade your local
  `terraform` before running this (the repo currently has 1.6.5 on PATH).
- Admin AWS credentials for the **MojeRODos account** in your shell:
  ```sh
  export AWS_PROFILE=mojerodos          # or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
  aws sts get-caller-identity            # confirm the right account
  ```

## Run it

```sh
cd aws/bootstrap
terraform init
terraform plan      # review: OIDC provider, IAM role, S3 bucket
terraform apply     # you apply — the agent stops before this step
```

> `mojerodos-tfstate` must be globally unique in S3. The name is distinctive enough to almost
> certainly be free; if `apply` reports a name collision, change `state_bucket_name` in
> `terraform.tfvars` **and** the `bucket` in every root module's backend block, then re-run.

## Wire CI to the role

The workflow reads the role ARN from a **repo variable** (ARNs aren't secret):

```sh
gh variable set AWS_DEPLOY_ROLE_ARN --repo miveal/mojerodos-infra \
  --body "$(terraform output -raw cicd_deploy_role_arn)"
```

Also create the **`prod` GitHub Environment** (Settings → Environments) with a required reviewer
— that's the manual approval gate for applies, and its subject (`environment:prod`) is what the
role's trust policy allows.

## State for this bootstrap module

Uses **local state** (`terraform.tfstate`, git-ignored). Optional hardening after first apply:
migrate it into the bucket it just created — add a `backend "s3"` block
(`key = "aws/bootstrap/terraform.tfstate"`, `use_lockfile = true`) and `terraform init -migrate-state`.

## Don't forget

Commit the generated `.terraform.lock.hcl` (include Linux for CI):

```sh
terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64
```
