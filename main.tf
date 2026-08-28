module "network" {
  source = "./modules/network"

  # Nothing in the network module reads a service resource, so without this the
  # VPC can be attempted before the Compute API is enabled.
  depends_on = [google_project_service.compute]

  prefix = local.prefix
  region = local.gcp_region
}

module "runner" {
  source = "./modules/runner"
  count  = var.runner_enabled ? 1 : 0

  # The runner's IAM bindings do not feed any value this module consumes, so
  # nothing orders them ahead of the instance group implicitly. The subnet's
  # NAT ordering is handled inside the network module's output.
  depends_on = [
    google_project_service.compute,
    google_project_iam_member.runner_instance_read,
  ]

  prefix       = local.prefix
  region       = local.gcp_region
  labels       = local.labels
  machine_type = local.runner_machine_type

  runner_subnet_id      = module.network.runner_subnet_id
  service_account_email = google_service_account.runner.email

  nuon_install_id        = local.nuon_install_id
  runner_id              = local.runner_id
  runner_api_url         = local.runner_api_url
  runner_api_token       = local.runner_api_token
  runner_init_script_url = local.runner_init_script_url
}
