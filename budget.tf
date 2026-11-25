data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "monthly_budget" {
  name            = "ipsr-monthly-budget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 50
  time_grain = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
    end_date   = "2027-11-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [
      "awsipsrkochi@gmail.com"
    ]
  }
}