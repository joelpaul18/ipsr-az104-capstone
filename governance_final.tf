# Diagnostic Settings on Production Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  name                       = "diag-stipsrprodjoel01"
  target_resource_id         = azurerm_storage_account.prod_storage.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_metric {
    category = "Transaction"
  }
}

