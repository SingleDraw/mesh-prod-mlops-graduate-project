
# AKS cluster definition
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix # must be unique across Azure

  sku_tier = "Free"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s" # "Standard_DS2_v2"
    # small economic disc size for testing
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }
}
