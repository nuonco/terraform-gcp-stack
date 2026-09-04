locals {
  account_id   = "ncs-${substr(md5("${var.nuon_install_id}/${var.name}"), 0, 26)}"
  display_name = lookup(var.parameters, "display_name", "${var.nuon_install_id}-${var.name}")
}

resource "google_service_account" "main" {
  project      = var.gcp_project_id
  account_id   = local.account_id
  display_name = local.display_name
  description  = lookup(var.parameters, "description", "")
}
