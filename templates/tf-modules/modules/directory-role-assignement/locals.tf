locals {
  cloud_app_admin_role_id = one([
    for t in data.azuread_directory_role_templates.all.role_templates :
    t.object_id if t.display_name == var.cloud_app_admin_role_name
  ])
}
