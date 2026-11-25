# App Subnet (10.10.3.0/24)
resource "azurerm_subnet" "snet_app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.3.0/24"]
}

# NSG for Internal App Tier (Allow traffic only from snet-web 10.10.1.0/24)
resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-app"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  security_rule {
    name                       = "Allow-Web-To-App"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "8080"]
    source_address_prefix      = "10.10.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Bastion-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/26"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_subnet_network_security_group_association" "snet_app_nsg" {
  subnet_id                 = azurerm_subnet.snet_app.id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}

# Private NIC & Internal Linux App VM (Zone 2)
resource "azurerm_network_interface" "app_nic" {
  name                = "nic-vm-app-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                            = "vm-app-prod"
  resource_group_name             = azurerm_resource_group.prod.name
  location                        = azurerm_resource_group.prod.location
  size                            = "Standard_B2ls_v2"
  zone                            = "2"
  admin_username                  = "azureuser"
  admin_password                  = "Ipsr@App2026!"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.app_nic.id]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.prod_identity.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

# Autoscale Rule for Web VM Scale Set (2 to 4 instances based on CPU)
resource "azurerm_monitor_autoscale_setting" "web_autoscale" {
  name                = "autoscale-vmss-web"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.web_vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

# Recovery Services Vault & Daily VM Backup Policy
resource "azurerm_recovery_services_vault" "rsv" {
  name                = "rsv-nw-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "Standard"

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_backup_policy_vm" "daily_vm" {
  name                = "policy-daily-vm-backup"
  resource_group_name = azurerm_resource_group.prod.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "app_vm_backup" {
  resource_group_name = azurerm_resource_group.prod.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  source_vm_id        = azurerm_linux_virtual_machine.app_vm.id
  backup_policy_id    = azurerm_backup_policy_vm.daily_vm.id
}

output "app_vm_private_ip" {
  value = azurerm_network_interface.app_nic.private_ip_address
}