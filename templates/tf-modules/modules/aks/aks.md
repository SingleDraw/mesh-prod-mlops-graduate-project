# AKS terraform module
    Cheap AKS cluster definition with Terraform. This module creates a basic AKS cluster with a single node pool. It is meant for quick testing and learning.

```terraform
# use this module in your main.tf like this:
module "aks" {
  source              = "./modules/aks"
  name                = "my-aks-cluster"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myakscluster" # must be unique across Azure
}
```