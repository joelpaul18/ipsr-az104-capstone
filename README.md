# IPSR AZ-104 Capstone Project — Multi-Tier Hub-and-Spoke Azure Infrastructure

**Author:** Joel Paul  
**Region:** Central India (`centralindia`)  
**Tooling:** Terraform (`azurerm ~> 4.0`), Azure CLI, Azure Portal  

---

## Overview

This repository contains the Infrastructure as Code (IaC) configuration for the **IPSR Solutions Limited AZ-104 Capstone Project**. The deployment implements a segmented, hub-and-spoke Azure cloud environment covering governance guardrails, geo-redundant private storage, load-balanced compute, private bastion access, and centralized monitoring.

---

## Architecture & Design Decisions

```text
+-----------------------------------------------------------------------+
|                       Azure Subscription (Central India)              |
|  Policies: Allowed Locations | Require Project Tag | Allowed VM SKUs  |
|  Budget: ipsr-monthly-budget (50 INR, 80% Alert)                      |
+-----------------------------------------------------------------------+
       |                                                 |
       v                                                 v
+-------------------------------+       +-------------------------------+
|  Hub VNet: vnet-hub-prod      |       |  Spoke VNet: vnet-nw-prod     |
|  CIDR: 10.0.0.0/16            |<----->|  CIDR: 10.10.0.0/16           |
|                               | Peered|                               |
|  - AzureBastionSubnet         |       |  - snet-web (10.10.1.0/24)    |
|    (10.0.1.0/26)              |       |    * Standard LB (lb-web-prod)|
|    * Azure Bastion            |       |    * Linux VMSS (Nginx)       |
|      (bas-hub-prod)           |       |    * NSG (nsg-web)            |
|                               |       |                               |
|  - GatewaySubnet              |       |  - snet-data (10.10.2.0/24)   |
|    (10.0.2.0/27)              |       |    * Private Endpoint         |
+-------------------------------+       |      (pe-stipsrprodjoel01-file)
                                        |    * Private DNS Zone Link    |
                                        |                               |
                                        |  - snet-app (10.10.3.0/24)    |
                                        |    * Internal VM (vm-app-prod)|
                                        |    * NSG (nsg-app)            |
                                        |    * RSV Backup (rsv-nw-prod) |
                                        +-------------------------------+
                                                        |
                                                        v
                                        +-------------------------------+
                                        |  Storage & Monitoring         |
                                        |  - stipsrprodjoel01 (GRS)     |
                                        |  - Log Analytics (law-nw-prod)|
                                        |  - Alerts (CPU, LB, Activity) |
                                        |  - CanNotDelete Locks         |
                                        +-------------------------------+
