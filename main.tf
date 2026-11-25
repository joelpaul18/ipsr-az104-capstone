terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

resource "azurerm_resource_group" "prod" {
  name     = "rg-nw-prod"
  location = "centralindia"
  tags = {
    Environment = "Production"
    Project     = "IPSR-AZ104"
  }
}

resource "azurerm_resource_group" "dev" {
  name     = "rg-nw-dev"
  location = "centralindia"
  tags = {
    Environment = "Development"
    Project     = "IPSR-AZ104"
  }
}