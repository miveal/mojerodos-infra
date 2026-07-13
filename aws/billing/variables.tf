variable "monthly_budget_amount" {
  description = "Monthly cost budget threshold in USD. Alerts fire against this."
  type        = string
  default     = "20"
}

variable "alert_email" {
  description = "Email address that receives budget + anomaly alerts (notification target only)."
  type        = string
  default     = "dariusz89k@gmail.com"
}

variable "anomaly_impact_threshold" {
  description = "Absolute USD impact above which a cost anomaly triggers an immediate alert."
  type        = string
  default     = "5"
}

variable "cost_allocation_tag_keys" {
  description = "User-defined tag keys to activate as cost-allocation tags (so Cost Explorer can break spend down by them)."
  type        = list(string)
  default     = ["Project", "Component", "Environment", "ManagedBy", "Repository"]
}

variable "activate_cost_allocation_tags" {
  description = <<-EOT
    Whether to activate cost-allocation tag keys. AWS only lets a key be activated AFTER it has
    been seen on a billed resource (~24h discovery lag), so this MUST be false on a brand-new
    account or the apply fails with "Tag keys not found". Flip to true in a follow-up apply once
    the keys have been discovered (>24h after the first tagged resource exists).
  EOT
  type        = bool
  default     = false
}
