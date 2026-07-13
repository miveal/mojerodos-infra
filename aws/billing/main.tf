locals {
  tags = {
    Project     = "mojerodos"
    Environment = "shared" # account-global, not env-specific
    Component   = "billing"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
  }
}

# Monthly cost budget with threshold alerts emailed directly (no SNS needed).
resource "aws_budgets_budget" "monthly_cost" {
  name         = "mojerodos-monthly-cost"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Warn as actual spend crosses 80% and 100%, and when forecast to exceed 100%.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

# Detect unusual per-service spend spikes and alert immediately over the impact threshold.
resource "aws_ce_anomaly_monitor" "service" {
  name              = "mojerodos-service-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "service" {
  name             = "mojerodos-anomaly-alerts"
  frequency        = "IMMEDIATE"
  monitor_arn_list = [aws_ce_anomaly_monitor.service.arn]

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = [var.anomaly_impact_threshold]
    }
  }
}

# Activate our tag keys as cost-allocation tags so Cost Explorer can group spend by them.
# GATED: AWS only lets you activate a tag key after it has been *seen* on a billed resource
# (~24h discovery lag), so on a brand-new account activating immediately fails with
# "Tag keys not found". Keep activate_cost_allocation_tags=false for the first apply; flip it
# true in a follow-up apply once the keys are discovered (>24h after first tagged resource).
resource "aws_ce_cost_allocation_tag" "this" {
  for_each = var.activate_cost_allocation_tags ? toset(var.cost_allocation_tag_keys) : toset([])

  tag_key = each.value
  status  = "Active"
}
