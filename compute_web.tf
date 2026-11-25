# Web Subnet (10.10.1.0/24)
resource "azurerm_subnet" "snet_web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# NSG for Web Tier (Allow HTTP 80)
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_subnet_network_security_group_association" "snet_web_nsg" {
  subnet_id                 = azurerm_subnet.snet_web.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

# Public IP & Standard Load Balancer
resource "azurerm_public_ip" "web_lb_pip" {
  name                = "pip-lb-web-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_lb" "web_lb" {
  name                = "lb-web-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.web_lb_pip.id
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_lb_backend_address_pool" "web_bepool" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "bepool-web"
}

resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "http-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.web_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_bepool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_outbound_rule" "web_outbound" {
  name                    = "outbound-internet"
  loadbalancer_id         = azurerm_lb.web_lb.id
  protocol                = "All"
  allocated_outbound_ports = 1024
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_bepool.id

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }
}

# Linux VM Scale Set (Web Tier)
resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {
  name                            = "vmss-web-prod"
  resource_group_name             = azurerm_resource_group.prod.name
  location                        = azurerm_resource_group.prod.location
  sku                             = "Standard_B2ls_v2"
  zones                           = ["2"]
  instances                       = 1
  admin_username                  = "azureuser"
  admin_password                  = "Ipsr@Web2026!"
  disable_password_authentication = false
  upgrade_mode                    = "Manual"

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable --now nginx
    echo "Hello Joel from $(hostname)" > /var/www/html/index.html
  EOF
  )

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                      = "nic-web-vmss"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.nsg_web.id

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.snet_web.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_bepool.id]
    }
  }

  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

output "web_lb_public_ip" {
  value = azurerm_public_ip.web_lb_pip.ip_address
}