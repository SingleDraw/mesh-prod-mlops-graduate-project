# NSG (Network Security Group)
+   działa na:
    * subnet
    * NIC
+   kontrola:
    * allow / deny
    * L3/L4 (IP, port, protocol)
+   stateless logic:
    * rules są proste (5-tuple)

```hcl

# NSG example definition
resource "azurerm_network_security_group" "example" {
  # ------ where NSG lives ------
  name                = "nsg-web"

  # !!! NSG musi być w tym samym regionie co VNet/subnet, do którego będzie przypisany
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "allow-http"
    # -- higher number = lower priority --
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    
    # -- * = any -- or specific IP/CIDR eg. 80.80.0.0/8" --
    source_address_prefix      = "*"

    # -- port or port range eg. 80-90 --
    destination_port_range     = "80"
    source_port_range          = "*"

    
    destination_address_prefix = "*"
  }
}

# association with subnet (recommended)
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# or association with NIC (very uncommon, but possible)
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

```

VNet
 ├── subnet A
 ├── subnet B
 └── subnet C

VM
 └── NIC
      └── IP w subnet

VNet
  ↓
Subnet (10.0.1.0/24)
  ↓
NIC (VM interface)
  ↓
VM

# Subnet
```hcl
resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

# NIC
```hcl
resource "azurerm_network_interface" "vm_nic" {
  name                = "vm-nic"
  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}
```