###############################################################################
# Runner service account
###############################################################################

resource "google_service_account" "runner" {
  account_id   = "${substr(local.prefix, 0, 23)}-runner"
  display_name = "Nuon runner for ${local.prefix}"

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

# init-mng-v2 auth: ctl-api independently reads the instance's nuon_runner_id
# via the Compute API using the runner's own token (the GCP mirror of the AWS
# ec2:DescribeTags grant), so the runner SA needs compute.instances.get.
resource "google_project_iam_custom_role" "runner_instance_read" {
  role_id     = "nuon_r_${md5("runner/${local.prefix}")}"
  title       = "Nuon runner instance read for ${local.prefix}"
  permissions = ["compute.instances.get"]

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_member" "runner_instance_read" {
  project = local.gcp_project_id
  role    = google_project_iam_custom_role.runner_instance_read.id
  member  = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# GKE node pool service account — least-privilege SA for GKE nodes
###############################################################################

resource "google_service_account" "gke_nodes" {
  count        = local.create_gke_node_pool_sa ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-gke-nodes"
  display_name = "GKE node pool SA for ${local.prefix}"

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_member" "gke_nodes_log_writer" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = local.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = local.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = local.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_reader" {
  count   = local.create_gke_node_pool_sa ? 1 : 0
  project = local.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

###############################################################################
# Provision service account + role
###############################################################################

resource "google_service_account" "provision" {
  count        = local.has_provision ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-prov"
  display_name = "Nuon provision for ${local.prefix}"

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_custom_role" "provision" {
  for_each    = local.provision_policies
  role_id     = "nuon_p_${md5("provision/${local.prefix}/${each.key}")}"
  title       = substr(each.key, 0, 100)
  description = "Nuon provision policy for ${local.prefix}: ${each.key}"
  permissions = each.value

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_member" "provision_custom_role" {
  for_each = local.provision_policies
  project  = local.gcp_project_id
  role     = google_project_iam_custom_role.provision[each.key].id
  member   = "serviceAccount:${google_service_account.provision[0].email}"
}

resource "google_project_iam_member" "provision_predefined_role" {
  count   = local.provision_predefined_role != "" ? 1 : 0
  project = local.gcp_project_id
  role    = local.provision_predefined_role
  member  = "serviceAccount:${google_service_account.provision[0].email}"
}

resource "google_service_account_iam_member" "provision_token_creator" {
  count              = local.has_provision ? 1 : 0
  service_account_id = google_service_account.provision[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Maintenance service account + role
###############################################################################

resource "google_service_account" "maintenance" {
  count        = local.has_maintenance ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-maint"
  display_name = "Nuon maintenance for ${local.prefix}"

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_custom_role" "maintenance" {
  for_each    = local.maintenance_policies
  role_id     = "nuon_m_${md5("maintenance/${local.prefix}/${each.key}")}"
  title       = substr(each.key, 0, 100)
  description = "Nuon maintenance policy for ${local.prefix}: ${each.key}"
  permissions = each.value

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_member" "maintenance_custom_role" {
  for_each = local.maintenance_policies
  project  = local.gcp_project_id
  role     = google_project_iam_custom_role.maintenance[each.key].id
  member   = "serviceAccount:${google_service_account.maintenance[0].email}"
}

resource "google_project_iam_member" "maintenance_predefined_role" {
  count   = local.maintenance_predefined_role != "" ? 1 : 0
  project = local.gcp_project_id
  role    = local.maintenance_predefined_role
  member  = "serviceAccount:${google_service_account.maintenance[0].email}"
}

resource "google_service_account_iam_member" "maintenance_token_creator" {
  count              = local.has_maintenance ? 1 : 0
  service_account_id = google_service_account.maintenance[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Deprovision service account + role
###############################################################################

resource "google_service_account" "deprovision" {
  count        = local.has_deprovision ? 1 : 0
  account_id   = "${substr(local.prefix, 0, 20)}-dep"
  display_name = "Nuon deprovision for ${local.prefix}"

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_custom_role" "deprovision" {
  for_each    = local.deprovision_policies
  role_id     = "nuon_d_${md5("deprovision/${local.prefix}/${each.key}")}"
  title       = substr(each.key, 0, 100)
  description = "Nuon deprovision policy for ${local.prefix}: ${each.key}"
  permissions = each.value

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_member" "deprovision_custom_role" {
  for_each = local.deprovision_policies
  project  = local.gcp_project_id
  role     = google_project_iam_custom_role.deprovision[each.key].id
  member   = "serviceAccount:${google_service_account.deprovision[0].email}"
}

resource "google_project_iam_member" "deprovision_predefined_role" {
  count   = local.deprovision_predefined_role != "" ? 1 : 0
  project = local.gcp_project_id
  role    = local.deprovision_predefined_role
  member  = "serviceAccount:${google_service_account.deprovision[0].email}"
}

resource "google_service_account_iam_member" "deprovision_token_creator" {
  count              = local.has_deprovision ? 1 : 0
  service_account_id = google_service_account.deprovision[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Break-glass service accounts + roles (dynamic, one per enabled role)
###############################################################################

resource "google_service_account" "break_glass" {
  for_each = local.enabled_break_glass_roles
  # account_id is a hash (see locals.tf); the legible key lives here so the SA
  # stays searchable (google_service_account has no labels field).
  account_id   = local.break_glass_account_ids[each.key]
  display_name = each.key
  description  = "Nuon break-glass SA: ${each.key}"

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_custom_role" "break_glass" {
  for_each    = local.break_glass_role_policies
  role_id     = local.break_glass_policy_role_ids[each.key]
  title       = substr("${each.value.role_key}: ${each.value.policy_name}", 0, 100)
  description = "Nuon break-glass policy: ${each.key}"
  permissions = each.value.permissions

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_member" "break_glass_custom_role" {
  for_each = local.break_glass_role_policies
  project  = local.gcp_project_id
  role     = google_project_iam_custom_role.break_glass[each.key].id
  member   = "serviceAccount:${google_service_account.break_glass[each.value.role_key].email}"
}

resource "google_project_iam_member" "break_glass_predefined_role" {
  for_each = { for k, v in local.enabled_break_glass_roles : k => v if v.predefined_role != "" }
  project  = local.gcp_project_id
  role     = each.value.predefined_role
  member   = "serviceAccount:${google_service_account.break_glass[each.key].email}"
}

resource "google_service_account_iam_member" "break_glass_token_creator" {
  for_each           = local.enabled_break_glass_roles
  service_account_id = google_service_account.break_glass[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}

###############################################################################
# Custom service accounts + roles (dynamic, one per enabled role)
###############################################################################

resource "google_service_account" "custom" {
  for_each = local.enabled_custom_roles
  # account_id is a hash (see locals.tf); the legible key lives here so the SA
  # stays searchable (google_service_account has no labels field).
  account_id   = local.custom_account_ids[each.key]
  display_name = each.key
  description  = "Nuon custom role SA: ${each.key}"

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_custom_role" "custom" {
  for_each    = local.custom_role_policies
  role_id     = local.custom_policy_role_ids[each.key]
  title       = substr("${each.value.role_key}: ${each.value.policy_name}", 0, 100)
  description = "Nuon custom role policy: ${each.key}"
  permissions = each.value.permissions

  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
  ]
}

resource "google_project_iam_member" "custom_custom_role" {
  for_each = local.custom_role_policies
  project  = local.gcp_project_id
  role     = google_project_iam_custom_role.custom[each.key].id
  member   = "serviceAccount:${google_service_account.custom[each.value.role_key].email}"
}

resource "google_project_iam_member" "custom_predefined_role" {
  for_each = { for k, v in local.enabled_custom_roles : k => v if v.predefined_role != "" }
  project  = local.gcp_project_id
  role     = each.value.predefined_role
  member   = "serviceAccount:${google_service_account.custom[each.key].email}"
}

resource "google_service_account_iam_member" "custom_token_creator" {
  for_each           = local.enabled_custom_roles
  service_account_id = google_service_account.custom[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.runner.email}"
}
