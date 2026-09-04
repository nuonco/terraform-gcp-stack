locals {
  zone_name = "${var.nuon_install_id}-${var.name}"
}

resource "google_dns_managed_zone" "main" {
  project       = var.gcp_project_id
  name          = local.zone_name
  dns_name      = var.parameters["dns_name"]
  visibility    = lookup(var.parameters, "visibility", "public")
  description   = lookup(var.parameters, "description", "${var.nuon_install_id}-${var.name} managed zone")
  force_destroy = lookup(var.parameters, "force_destroy", "false") == "true"

  dynamic "private_visibility_config" {
    for_each = lookup(var.parameters, "visibility", "public") == "private" ? [var.gcp_network_id] : []

    content {
      networks {
        network_url = private_visibility_config.value
      }
    }
  }

  lifecycle {
    precondition {
      condition     = lookup(var.parameters, "visibility", "public") != "private" || var.gcp_network_id != ""
      error_message = "gcp_network_id must be set when parameters.visibility is \"private\"."
    }

    precondition {
      condition     = length(local.zone_name) <= 63 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.zone_name))
      error_message = "custom DNS zone name ${local.zone_name} must be at most 63 characters, use lowercase letters, numbers, or hyphens, start with a letter, and end with a letter or number."
    }
  }
}
