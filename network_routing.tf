# Custom Route Table for Spoke Subnets (Hub-and-Spoke Traffic Control)
resource "azurerm_route_table" "spoke_rt" {
  name                = "rt-spoke-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  route {
    name           = "Route-To-Hub-VNet"
    address_prefix = "10.0.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  route {
    name           = "Route-Spoke-Internal"
    address_prefix = "10.10.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_subnet_route_table_association" "snet_web_rt" {
  subnet_id      = azurerm_subnet.snet_web.id
  route_table_id = azurerm_route_table.spoke_rt.id
}

resource "azurerm_subnet_route_table_association" "snet_app_rt" {
  subnet_id      = azurerm_subnet.snet_app.id
  route_table_id = azurerm_route_table.spoke_rt.id
}

# Link Private DNS Zone to Hub VNet for Hybrid Name Resolution
resource "azurerm_private_dns_zone_virtual_network_link" "file_dns_hub_link" {
  name                  = "link-vnet-hub-prod-file"
  resource_group_name   = azurerm_resource_group.prod.name
  private_dns_zone_name = azurerm_private_dns_zone.file_dns.name
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
}