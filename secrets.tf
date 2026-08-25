###############################################################################
# Auto-generated secrets
###############################################################################

resource "random_password" "auto_generate" {
  for_each = toset(local.auto_generate_secrets)
  length   = 63
  special  = false

  keepers = {
    secret_name = each.key
    install_id  = local.nuon_install_id
  }

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_secret_manager_secret" "auto_generate" {
  for_each  = toset(local.auto_generate_secrets)
  secret_id = "${local.prefix}-${each.key}"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_secret_manager_secret_version" "auto_generate" {
  for_each    = toset(local.auto_generate_secrets)
  secret      = google_secret_manager_secret.auto_generate[each.key].id
  secret_data = random_password.auto_generate[each.key].result

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_iam_member" "auto_generate_accessor" {
  for_each  = local.has_provision ? toset(local.auto_generate_secrets) : toset([])
  secret_id = google_secret_manager_secret.auto_generate[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.provision[0].email}"
}

###############################################################################
# Customer-provided secrets
###############################################################################

# Skip optional secrets left unset — an optional secret with no value shouldn't
# be created at all. Required secrets are always created: if one is left empty,
# GCP rejects the empty payload and surfaces the error instead of silently
# skipping a secret the install depends on.
locals {
  customer_secret_keys = toset(nonsensitive([for k, v in local.secrets : k if v.value != "" || v.required]))
}

resource "google_secret_manager_secret" "customer" {
  for_each  = local.customer_secret_keys
  secret_id = "${local.prefix}-${each.key}"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_secret_manager_secret_version" "customer" {
  for_each    = local.customer_secret_keys
  secret      = google_secret_manager_secret.customer[each.key].id
  secret_data = local.secrets[each.key].value

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_iam_member" "customer_accessor" {
  for_each  = local.has_provision ? local.customer_secret_keys : toset([])
  secret_id = google_secret_manager_secret.customer[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.provision[0].email}"
}

###############################################################################
# Telemetry export configuration
###############################################################################

resource "google_secret_manager_secret" "telemetry_export_config" {
  secret_id = "${local.prefix}-telemetry-export-config"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret_iam_member" "telemetry_export_config_accessor" {
  secret_id = google_secret_manager_secret.telemetry_export_config.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runner.email}"
}
