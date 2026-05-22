
# ACR - Azure Container Registry
# -----------------------------------------------------------------
resource "azurerm_container_registry" "this" {
    name                = var.container_registry_name
    resource_group_name = var.resource_group_name
    location            = var.location
    sku                 = "Basic"       # economical tier 
                                        # *(no firewall rules, no private endpoints)*
    # sku                 = "Premium"   # use premium tier if firewall rules are needed

    admin_enabled       = false      # disable username/password access 
                                     # (use SP with OIDC or managed identity)
    # network_rule_set {
    #     default_action = "Deny"
    #     # whitelist only
    #     ip_rule { 
    #         action = "Allow"
    #         value  = "YOUR.PUBLIC.IP/32"  # Replace with actual public IP or CIDR range for security
    #     }
    # }

    public_network_access_enabled = true  # Allow public endpoint, can be set to false if using private endpoints

    tags = var.tags
}

# RBAC for ACR Pullers (var.acr_pullers should contain object IDs of identities that need pull access, e.g. AKS managed identity or service principal)
resource "azurerm_role_assignment" "adf_acr_pull" {
    count                = length(var.acr_pullers) > 0 ? length(var.acr_pullers) : 0
    scope                = azurerm_container_registry.this.id
    role_definition_name = "AcrPull"
    principal_id         = var.acr_pullers[count.index]
}

# RBAC for ACR Pushers (var.acr_pushers should contain object IDs of identities that need push access, e.g. CI/CD service principal)
resource "azurerm_role_assignment" "adf_acr_push" {
    count                = length(var.acr_pushers) > 0 ? length(var.acr_pushers) : 0
    scope                = azurerm_container_registry.this.id
    role_definition_name = "AcrPush"
    principal_id         = var.acr_pushers[count.index]
}
