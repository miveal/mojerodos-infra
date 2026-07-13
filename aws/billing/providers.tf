# Budgets, Cost Explorer, Cost Anomaly Detection and cost-allocation tags are global
# services whose control-plane lives in us-east-1. This whole root targets us-east-1.
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = local.tags
  }
}
