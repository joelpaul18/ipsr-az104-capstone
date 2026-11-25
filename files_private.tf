# Production Virtual Network (10.10.0.0/16) & Data Subnet (10.10.2.0/24)
resource "azurerm_virtual_network" "prod_vnet" {
  name                = "vnet-nw-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  address_space       = ["10.10.0.0/16"]

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_subnet" "snet_data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

# 50 GiB Azure Files Share
resource "azurerm_storage_share" "dept_share" {
  name               = "dept-shared-files"
  storage_account_id = azurerm_storage_account.prod_storage.id
  quota              = 50
}

# Private DNS Zone for Azure Files
resource "azurerm_private_dns_zone" "file_dns" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.prod.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_dns_link" {
  name                  = "link-vnet-nw-prod-file"
  resource_group_name   = azurerm_resource_group.prod.name
  private_dns_zone_name = azurerm_private_dns_zone.file_dns.name
  virtual_network_id    = azurerm_virtual_network.prod_vnet.id
}

# Private Endpoint for Azure Files in snet-data
resource "azurerm_private_endpoint" "file_pe" {
  name                = "pe-stipsrprodjoel01-file"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  subnet_id           = azurerm_subnet.snet_data.id

  private_service_connection {
    name                           = "psc-stipsrprodjoel01-file"
    private_connection_resource_id = azurerm_storage_account.prod_storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-group-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.file_dns.id]
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

# Scoped Read-Only SAS Token for Shared Files
data "azurerm_storage_account_sas" "scoped_file_sas" {
  connection_string = azurerm_storage_account.prod_storage.primary_connection_string
  https_only        = true
  signed_version    = "2022-11-02"

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = false
    queue = false
    table = false
    file  = true
  }

  start  = "2026-11-25T00:00:00Z"
  expiry = "2026-12-02T00:00:00Z"

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

output "scoped_file_sas_token" {
  value     = data.azurerm_storage_account_sas.scoped_file_sas.sas
  sensitive = true
}