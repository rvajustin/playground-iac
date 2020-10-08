
variable "serviceName" {
    type = string
    default = "playground"
}

variable "stage" {
    type = string
    description = "The deployment stage"
    default = "dev"
}

variable "subscriptionId" {
    type = string
    description = "The Azure subscription ID"
}

variable "resource_prefix" {
    type = string
    default = "rvaj82"
}

variable "tenant" {
    type = string
}

variable "appId" {
    type = string
}

variable "password" {
    type = string
}

variable "owner" {
    type = string
    default = "me@rvajustin.com"
}

variable "creator" {
    type = string
    default = "me@rvajustin.com"
}

provider "azurerm" {
  version = "~>2.0"
  subscription_id = var.subscriptionId
  features {
     key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  globalPrefix = "${var.resource_prefix}-${var.serviceName}-${var.stage}"
  storaegAccountName = "st${var.resource_prefix}playground${var.stage}"
}

data "azurerm_client_config" "current" {}

# Resource group ################################################################

resource "azurerm_resource_group" "rg" {
  name = "rg-${var.serviceName}-${var.stage}"
  location = "eastus"

  tags = {
    environment = var.stage
    owner = var.owner
    creator = var.creator
  }
}

# AKS ################################################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.globalPrefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${local.globalPrefix}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = var.stage
    owner = var.owner
    creator = var.creator
  }
}