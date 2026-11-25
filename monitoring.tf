# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-nw-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

# Action Group for Alert Notifications
resource "azurerm_monitor_action_group" "alerts_ag" {
  name                = "ag-ipsr-alerts"
  resource_group_name = azurerm_resource_group.prod.name
  short_name          = "ipsralert"

  email_receiver {
    name                    = "admin-email"
    email_address           = "awsipsrkochi@gmail.com"
    use_common_alert_schema = true
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

# Diagnostic Settings on Standard Load Balancer
resource "azurerm_monitor_diagnostic_setting" "lb_diag" {
  name                       = "diag-lb-web-prod"
  target_resource_id         = azurerm_lb.web_lb.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_metric {
    category = "AllMetrics"
  }
}

# Metric Alert on Internal App VM CPU > 80%
resource "azurerm_monitor_metric_alert" "app_cpu_alert" {
  name                = "alert-vm-app-high-cpu"
  resource_group_name = azurerm_resource_group.prod.name
  scopes              = [azurerm_linux_virtual_machine.app_vm.id]
  description         = "Alert when vm-app-prod CPU exceeds 80 percent"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts_ag.id
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}