locals {
  bucket_name = "${var.nuon_install_id}-${var.name}"
}

resource "google_storage_bucket" "main" {
  project                     = var.gcp_project_id
  name                        = local.bucket_name
  location                    = lookup(var.parameters, "location", var.gcp_region)
  uniform_bucket_level_access = true
  force_destroy               = lookup(var.parameters, "force_destroy", "false") == "true"

  versioning {
    enabled = lookup(var.parameters, "versioning", "false") == "true"
  }

  lifecycle {
    precondition {
      condition     = length(local.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9._-]*[a-z0-9]$", local.bucket_name))
      error_message = "custom bucket name ${local.bucket_name} must be at most 63 characters, use lowercase letters, numbers, dots, underscores, or hyphens, and start and end with a letter or number."
    }
  }
}
