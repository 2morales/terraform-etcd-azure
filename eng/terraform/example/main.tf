provider "azurerm" {
  version = "=2.1.0"

  features {}
}

locals {
  deployment_name = "etcd"
  location        = "eastus"
  zone_name       = "example.com"
}

# Create resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.deployment_name}-deployment-${local.location}"
  location = local.location
}

# Create containers virtual network resources
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.deployment_name}-${local.location}"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "this" {
  name                 = "snet-${local.deployment_name}-${local.location}"
  resource_group_name  = azurerm_resource_group.this.name
  address_prefix       = "10.0.0.0/24"
  virtual_network_name = azurerm_virtual_network.this.name
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "snet-delegation-${local.deployment_name}-${local.location}"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_profile" "this" {
  name                = "np-${local.deployment_name}-${local.location}"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name

  container_network_interface {
    name = "nic-${local.deployment_name}-${local.location}"

    ip_configuration {
      name      = "ipc-${local.deployment_name}-${local.location}"
      subnet_id = azurerm_subnet.this.id
    }
  }
}

# Create private DNS zone
resource "azurerm_private_dns_zone" "this" {
  name                = local.zone_name
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# Create etcd cluster nodes
module "etcd_node1" {
  source = "../modules/etcd-node"

  deployment_name      = "${local.deployment_name}1"
  location             = local.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = azurerm_subnet.this.id
  network_profile_id   = azurerm_network_profile.this.id
  etcd_initial_cluster = "${local.deployment_name}1=http://${local.deployment_name}1.${local.zone_name}:2380,${local.deployment_name}2=http://${local.deployment_name}2.${local.zone_name}:2380,${local.deployment_name}3=http://${local.deployment_name}3.${local.zone_name}:2380"
  zone_name            = local.zone_name
}

module "etcd_node2" {
  source = "../modules/etcd-node"

  deployment_name      = "${local.deployment_name}2"
  location             = local.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = azurerm_subnet.this.id
  network_profile_id   = azurerm_network_profile.this.id
  etcd_initial_cluster = "${local.deployment_name}1=http://${local.deployment_name}1.${local.zone_name}:2380,${local.deployment_name}2=http://${local.deployment_name}2.${local.zone_name}:2380,${local.deployment_name}3=http://${local.deployment_name}3.${local.zone_name}:2380"
  zone_name            = local.zone_name
}

module "etcd_node3" {
  source = "../modules/etcd-node"

  deployment_name      = "${local.deployment_name}3"
  location             = local.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = azurerm_subnet.this.id
  network_profile_id   = azurerm_network_profile.this.id
  etcd_initial_cluster = "${local.deployment_name}1=http://${local.deployment_name}1.${local.zone_name}:2380,${local.deployment_name}2=http://${local.deployment_name}2.${local.zone_name}:2380,${local.deployment_name}3=http://${local.deployment_name}3.${local.zone_name}:2380"
  zone_name            = local.zone_name
}
