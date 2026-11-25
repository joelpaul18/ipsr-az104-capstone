# 1. Availability Alert: Load Balancer Health Probe Status
resource "azurerm_monitor_metric_alert" "lb_availability_alert" {
  name                = "alert-lb-health-probe"
  resource_group_name = azurerm_resource_group.prod.name
  scopes              = [azurerm_lb.web_lb.id]
  description         = "Alert when web Load Balancer health probe availability drops below 100%"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/loadBalancers"
    metric_name      = "DipAvailability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts_ag.id
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

# 2. Security / Unauthorized Access Alert: Failed Administrative Operations
resource "azurerm_monitor_activity_log_alert" "denied_ops_alert" {
  name                = "alert-denied-operations"
  resource_group_name = azurerm_resource_group.prod.name
  location            = "global"
  scopes              = [azurerm_resource_group.prod.id]
  description         = "Alert on failed or unauthorized administrative operations in rg-nw-prod"

  criteria {
    category = "Administrative"
    status   = "Failed"
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts_ag.id
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}