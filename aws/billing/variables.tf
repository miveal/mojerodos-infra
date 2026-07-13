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
