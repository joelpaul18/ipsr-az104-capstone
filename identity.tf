resource "azurerm_user_assigned_identity" "prod_identity" {
  name                = "id-nw-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_user_assigned_identity" "dev_identity" {
  name                = "id-nw-dev"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  tags = {
    Environment = "Development"
    Project     = "IPSR-AZ104"
  }
}