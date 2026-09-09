locals {
  # SA email / uniqueId maps for the phone-home payload. The numeric uniqueId is
  # the OIDC "sub" claim, used downstream to bind federated trust policies.
  break_glass_sa_emails     = { for k, v in google_service_account.break_glass : k => v.email }
  custom_sa_emails          = { for k, v in google_service_account.custom : k => v.email }
  break_glass_sa_unique_ids = { for k, v in google_service_account.break_glass : k => v.unique_id }
  custom_sa_unique_ids      = { for k, v in google_service_account.custom : k => v.unique_id }

  # Key names mirror what the legacy tfvars flow reported, so app templates
  # referencing `nuon.install_stack.outputs.*` resolve identically whether the
  # customer applied the old module or this one. request_type, phone_home_type,
  # and inputs are injected by the stack_phone_home resource.
  phone_home_payload = merge({
    project_id                       = local.gcp_project_id
    region                           = local.gcp_region
    network_name                     = module.network.network_name
    network_id                       = module.network.network_id
    public_subnet_name               = module.network.public_subnet_name
    private_subnet_name              = module.network.private_subnet_name
    runner_subnet_name               = module.network.runner_subnet_name
    runner_service_account_email     = google_service_account.runner.email
    runner_service_account_unique_id = google_service_account.runner.unique_id
    provision_sa_email               = local.has_provision ? google_service_account.provision[0].email : ""
    provision_sa_unique_id           = local.has_provision ? google_service_account.provision[0].unique_id : ""
    maintenance_sa_email             = local.has_maintenance ? google_service_account.maintenance[0].email : ""
    maintenance_sa_unique_id         = local.has_maintenance ? google_service_account.maintenance[0].unique_id : ""
    deprovision_sa_email             = local.has_deprovision ? google_service_account.deprovision[0].email : ""
    deprovision_sa_unique_id         = local.has_deprovision ? google_service_account.deprovision[0].unique_id : ""
    break_glass_sa_emails            = local.break_glass_sa_emails
    break_glass_sa_unique_ids        = local.break_glass_sa_unique_ids
    custom_sa_emails                 = local.custom_sa_emails
    custom_sa_unique_ids             = local.custom_sa_unique_ids
    gke_node_pool_sa_email           = local.gke_node_pool_sa_email
    gke_node_pool_sa_unique_id       = local.gke_node_pool_sa_unique_id
    runner_instance_group            = local.runner_instance_group
    install_inputs                   = local.install_inputs
    runner_enabled                   = var.runner_enabled
    custom_nested_stacks             = local.custom_stack_outputs
  }, local.all_secret_names)
}

# Reported through the stack provider rather than a local-exec curl. Two reasons:
# the request now carries an Authorization header, and a token on a curl command
# line would be visible in process arguments and Terraform's log output; and the
# provider owns retries and error reporting instead of shelling out.
#
# phone_home_url comes from the config data source — it embeds a per-stack-version
# identifier the caller has no other way to know, which is what lets this module
# take install_id alone.
#
# The resource lifecycle drives request_type: Create on first apply, Update when
# the payload changes, Delete on destroy. That replaces the always_run timestamp
# trigger, which forced a report on every apply whether or not anything moved.
resource "stack_phone_home" "this" {
  depends_on = [
    google_project_service.compute,
    google_project_service.secret_manager,
    google_project_service.iam_credentials,
    google_project_service.cloud_resource_manager,
    module.network,
    module.runner,
    google_service_account.runner,
    google_service_account.provision,
    google_service_account.maintenance,
    google_service_account.deprovision,
    google_service_account.break_glass,
    google_service_account.custom,
    google_service_account.gke_nodes,
    google_secret_manager_secret_version.auto_generate,
    google_secret_manager_secret_version.customer,
    google_secret_manager_secret.telemetry_export_config,
    google_secret_manager_secret_iam_member.telemetry_export_config_accessor,
  ]

  install_id      = local.nuon_install_id
  phone_home_url  = local.phone_home_url
  phone_home_type = "gcp"

  # Not part of the report: the authenticated phone-home URL is the same for
  # every version, so this is what makes a newly generated one show as a diff.
  stack_version_id = data.stack_config.this.stack_version_id

  payload = jsonencode(local.phone_home_payload)

  # The effective input values (control plane merged with var.inputs). The API
  # persists these as the install's current inputs, which is what makes the
  # inputs map a way to set input values — distinct from `payload`, which
  # records stack outputs.
  inputs = local.install_inputs

  # Hard preconditions rather than `check` blocks (which only warn, see
  # checks.tf): a typo'd input name would otherwise be silently dropped by the
  # API's own validation and the value never set.
  lifecycle {
    # Only reachable when the google provider itself has no default for the
    # value and neither the caller nor the control plane supplied one. Caught
    # here rather than left to the provider, which would fail partway through
    # with a less actionable error.
    precondition {
      condition     = length(local.missing_gcp_target) == 0
      error_message = "no ${join(" or ", local.missing_gcp_target)} could be resolved for this install; set ${join(" and ", local.missing_gcp_target)} on the google provider, or on this module."
    }

    precondition {
      condition     = length(local.unknown_input_keys) == 0
      error_message = "var.inputs contains keys the app does not declare as customer-facing inputs: ${join(", ", local.unknown_input_keys)}. Declared inputs: ${join(", ", keys(data.stack_config.this.install_inputs))}."
    }

    precondition {
      condition     = length(local.missing_required_inputs) == 0
      error_message = "the app requires a value for these inputs: ${join(", ", local.missing_required_inputs)}."
    }

    precondition {
      condition     = length(local.unknown_secret_keys) == 0
      error_message = "var.secrets contains keys the app does not declare as customer-facing secrets: ${join(", ", local.unknown_secret_keys)}. Declared secrets: ${join(", ", keys(nonsensitive(data.stack_config.this.secrets)))}."
    }

    precondition {
      condition     = length(local.missing_required_secrets) == 0
      error_message = "the app requires a value for these secrets: ${join(", ", local.missing_required_secrets)}."
    }

    precondition {
      condition     = length(local.unknown_role_keys) == 0
      error_message = "var.roles contains keys that match no role: ${join(", ", local.unknown_role_keys)}. Valid keys: ${join(", ", local.display_role_keys)}."
    }

    precondition {
      condition     = length(local.duplicate_custom_stack_names) == 0
      error_message = "custom stack names must be unique; duplicates: ${join(", ", local.duplicate_custom_stack_names)}."
    }

    precondition {
      condition     = length(local.unsupported_custom_stack_modules) == 0
      error_message = "unsupported custom stack modules: ${join(", ", local.unsupported_custom_stack_modules)}. Supported modules: ${join(", ", sort(tolist(local.supported_custom_stack_modules)))}."
    }

    precondition {
      condition     = length(local.missing_custom_stack_input_names) == 0
      error_message = "custom_stacks input_parameters reference inputs the install does not have: ${join(", ", local.missing_custom_stack_input_names)}. Known inputs: ${join(", ", keys(local.install_inputs))}."
    }
  }
}
