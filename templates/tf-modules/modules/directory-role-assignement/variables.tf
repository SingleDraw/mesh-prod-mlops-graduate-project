variable cloud_app_admin_role_name {
  description = "Name of the Azure AD role to assign to the platform SP for managing app registrations (e.g. 'Cloud Application Administrator')"
  type        = string
  default     = "Cloud Application Administrator"
}

variable "principal_object_id" {
  description = "Object ID of the principal (e.g. service principal) to which the directory role will be assigned"
  type        = string
}