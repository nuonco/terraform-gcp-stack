# Output names mirror the phone-home payload so anything reading
# `terraform output` or `nuon.install_stack.outputs.*` sees the same key set.

output "project_id" {
  value = local.gcp_project_id
}

output "region" {
  value = local.gcp_region
}

output "network_name" {
  value = module.network.network_name
}

output "network_id" {
  value = module.network.network_id
}

output "public_subnet_name" {
  value = module.network.public_subnet_name
}

output "private_subnet_name" {
  value = module.network.private_subnet_name
}

output "runner_subnet_name" {
  value = module.network.runner_subnet_name
}

output "runner_service_account_email" {
  value = google_service_account.runner.email
}

output "runner_service_account_unique_id" {
  value       = google_service_account.runner.unique_id
  description = "Numeric uniqueId (OIDC 'sub') of the runner service account. Used to bind federated AWS reader role trust policies."
}

output "gke_node_pool_sa_email" {
  value       = local.gke_node_pool_sa_email
  description = "Node-pool service account email: the caller-supplied one if set, else the one this module created, else empty."
}

output "gke_node_pool_sa_unique_id" {
  value       = local.gke_node_pool_sa_unique_id
  description = "Numeric uniqueId (OIDC 'sub') of the GKE node pool service account. Empty when an external email was supplied, since only a created SA has a known uniqueId."
}

output "provision_sa_email" {
  value = local.has_provision ? google_service_account.provision[0].email : ""
}

output "provision_sa_unique_id" {
  value       = local.has_provision ? google_service_account.provision[0].unique_id : ""
  description = "Numeric uniqueId (OIDC 'sub') of the provision service account."
}

output "maintenance_sa_email" {
  value = local.has_maintenance ? google_service_account.maintenance[0].email : ""
}

output "maintenance_sa_unique_id" {
  value       = local.has_maintenance ? google_service_account.maintenance[0].unique_id : ""
  description = "Numeric uniqueId (OIDC 'sub') of the maintenance service account."
}

output "deprovision_sa_email" {
  value = local.has_deprovision ? google_service_account.deprovision[0].email : ""
}

output "deprovision_sa_unique_id" {
  value       = local.has_deprovision ? google_service_account.deprovision[0].unique_id : ""
  description = "Numeric uniqueId (OIDC 'sub') of the deprovision service account."
}

output "break_glass_sa_emails" {
  value       = local.break_glass_sa_emails
  description = "Map of break-glass role name to service account email."
}

output "break_glass_sa_unique_ids" {
  value       = local.break_glass_sa_unique_ids
  description = "Map of break-glass role name to service account numeric uniqueId."
}

output "custom_sa_emails" {
  value       = local.custom_sa_emails
  description = "Map of custom role name to service account email."
}

output "custom_sa_unique_ids" {
  value       = local.custom_sa_unique_ids
  description = "Map of custom role name to service account numeric uniqueId."
}

output "install_inputs" {
  value       = local.install_inputs
  description = "Effective customer-facing input values: control-plane values merged with var.inputs overrides, as reported back to Nuon."
}

output "sensitive_input_names" {
  value       = data.stack_config.this.sensitive_input_names
  description = "Names of inputs the app marks sensitive. The install_inputs map itself is not marked sensitive (Terraform maps are all-or-nothing); use this list to handle those values carefully downstream."
}

output "secret_names" {
  value       = local.all_secret_names
  description = "Map of <secret_name>_secret_name to fully qualified GCP Secret Manager resource names."
}

# Always present, even when no custom stacks are defined, so the shape matches
# the other install-stack paths.
output "custom_nested_stacks" {
  value = {}
}

output "runner_instance_group" {
  value       = local.runner_instance_group
  description = "Name of the runner's managed instance group. Empty when the runner is disabled."
}

output "runner_enabled" {
  value = var.runner_enabled
}
