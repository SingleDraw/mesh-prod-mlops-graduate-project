locals {
  assignments_map = {
    for pair in flatten([
      for ai, a in var.assignments : [
        for ri, r in a.role_definitions : {
          key   = "${ai}-${md5(ri)}"
          scope = a.scope
          role  = r
        }
      ]
    # ]) : "${pair.scope}|${pair.role}" => {
    ]) : pair.key => {
      scope        = pair.scope
      role         = pair.role
      principal_id = var.principal_id
    }
  }
}