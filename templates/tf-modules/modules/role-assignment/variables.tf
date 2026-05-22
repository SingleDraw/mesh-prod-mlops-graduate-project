variable "assignments" {
  description = "List of role assignments to create. Each item should have a 'scope' and a list of 'role_definitions'."
  type = list(object({
    scope            = string
    role_definitions = list(string)
  }))
}

variable "principal_id" {
  description = "Object ID of the SP to assign roles to"
  type        = string
}