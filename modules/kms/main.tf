locals {
  key_name_prefix = trimsuffix(substr("${var.nuon_install_id}-${var.name}", 0, 54), "-")
  key_name        = "${local.key_name_prefix}-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4

  keepers = {
    install_id = var.nuon_install_id
    stack_name = var.name
  }
}

resource "google_kms_key_ring" "main" {
  project  = var.gcp_project_id
  name     = local.key_name
  location = lookup(var.parameters, "location", var.gcp_region)

  lifecycle {
    precondition {
      condition     = can(regex("^[A-Za-z0-9_-]+$", local.key_name_prefix))
      error_message = "custom KMS name prefix ${local.key_name_prefix} must use only letters, numbers, underscores, or hyphens."
    }
  }
}

resource "google_kms_crypto_key" "main" {
  name            = local.key_name
  key_ring        = google_kms_key_ring.main.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = lookup(var.parameters, "rotation_period", "7776000s")
}
