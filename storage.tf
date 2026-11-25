resource "azurerm_storage_account" "prod_storage" {
  name                     = "stipsrprodjoel01"
  resource_group_name      = azurerm_resource_group.prod.name
  location                 = azurerm_resource_group.prod.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_storage_container" "business_docs" {
  name                  = "business-docs"
  storage_account_id    = azurerm_storage_account.prod_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "app_assets" {
  name                  = "app-assets"
  storage_account_id    = azurerm_storage_account.prod_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.prod_storage.id

  rule {
    name    = "archive-old-business-docs"
    enabled = true

    filters {
      prefix_match = ["business-docs/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }
}