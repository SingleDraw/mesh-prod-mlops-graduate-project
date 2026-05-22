resource "azurerm_role_assignment" "this" {
  for_each = local.assignments_map

  scope                             = each.value.scope
  principal_id                      = each.value.principal_id
  role_definition_name              = each.value.role
  skip_service_principal_aad_check = true
}

/*
Usage Example:
----------------------------

module "rbac" {
  source       = "./modules/role-assignment"
  principal_id = module.service_principal.object_id

  assignments = [
    {
      scope            = data.azurerm_subscription.current.id
      role_definitions = ["User Access Administrator", "Contributor"]
    },
    {
      scope            = azurerm_resource_group.rg.id
      role_definitions = ["Contributor"]
    },
    {
      scope            = azurerm_storage_account.storage.id
      role_definitions = ["Storage Blob Data Contributor"]
    }
  ]
}
*/