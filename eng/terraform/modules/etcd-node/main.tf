# Create node storage resources
resource "azurerm_storage_account" "this" {
  name                     = "strg${var.deployment_name}${var.location}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  static_website {}
}

resource "azurerm_storage_share" "this" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.this.name
}

# Create node container resource
resource "azurerm_container_group" "this" {
  name                = "aci-${var.deployment_name}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "private"
  network_profile_id  = var.network_profile_id
  os_type             = "Linux"

  container {
    name   = "etcd"
    image  = "quay.io/coreos/etcd:v3.4.5"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      "ETCD_NAME"                        = var.deployment_name
      "ETCD_DATA_DIR"                    = "/${var.deployment_name}.etcd"
      "ETCD_LISTEN_PEER_URLS"            = "http://0.0.0.0:2380"
      "ETCD_LISTEN_CLIENT_URLS"          = "http://0.0.0.0:2379"
      "ETCD_CORS"                        = "*"
      "ETCD_INITIAL_CLUSTER_STATE"       = "new"
      "ETCD_INITIAL_CLUSTER"             = var.etcd_initial_cluster
      "ETCD_INITIAL_ADVERTISE_PEER_URLS" = "http://${var.deployment_name}.${var.zone_name}:2380"
      "ETCD_ADVERTISE_CLIENT_URLS"       = "http://${var.deployment_name}.${var.zone_name}:2380"
    }

    volume {
      name                 = "vol-${var.deployment_name}-${var.location}"
      mount_path           = "/${var.deployment_name}.etcd"
      storage_account_name = azurerm_storage_account.this.name
      storage_account_key  = azurerm_storage_account.this.primary_access_key
      share_name           = azurerm_storage_share.this.name
    }

    ports {
      port     = 2380
      protocol = "TCP"
    }

    ports {
      port     = 2379
      protocol = "TCP"
    }
  }
}

# Create container A host DNS record
resource "azurerm_private_dns_a_record" "this" {
  name                = var.deployment_name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_container_group.this.ip_address]
}
