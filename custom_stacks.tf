locals {
  supported_custom_stack_modules = toset([
    "bucket",
    "dns",
    "kms",
    "service_account",
  ])
  custom_stack_names = [for stack in data.stack_config.this.custom_stacks : stack.name]
  duplicate_custom_stack_names = toset([
    for name in local.custom_stack_names : name
    if length([for candidate in local.custom_stack_names : candidate if candidate == name]) > 1
  ])
  unsupported_custom_stack_modules = toset([
    for stack in data.stack_config.this.custom_stacks : stack.module
    if !contains(local.supported_custom_stack_modules, stack.module)
  ])
  missing_custom_stack_input_names = tolist(setsubtract(
    toset(flatten([for stack in data.stack_config.this.custom_stacks : values(stack.input_parameters)])),
    toset(keys(local.install_inputs)),
  ))

  custom_bucket_stacks = {
    for stack in data.stack_config.this.custom_stacks : stack.name => stack
    if stack.module == "bucket" && !contains(local.duplicate_custom_stack_names, stack.name)
  }
  custom_dns_stacks = {
    for stack in data.stack_config.this.custom_stacks : stack.name => stack
    if stack.module == "dns" && !contains(local.duplicate_custom_stack_names, stack.name)
  }
  custom_kms_stacks = {
    for stack in data.stack_config.this.custom_stacks : stack.name => stack
    if stack.module == "kms" && !contains(local.duplicate_custom_stack_names, stack.name)
  }
  custom_service_account_stacks = {
    for stack in data.stack_config.this.custom_stacks : stack.name => stack
    if stack.module == "service_account" && !contains(local.duplicate_custom_stack_names, stack.name)
  }
}

module "custom_bucket" {
  source   = "./modules/bucket"
  for_each = local.custom_bucket_stacks

  depends_on = [google_project_service.storage]

  nuon_install_id = local.nuon_install_id
  name            = each.key
  gcp_project_id  = local.gcp_project_id
  gcp_region      = local.gcp_region
  parameters = merge(each.value.parameters, {
    for parameter_name, input_name in each.value.input_parameters :
    parameter_name => lookup(local.install_inputs, input_name, "")
  })
}

module "custom_dns" {
  source   = "./modules/dns"
  for_each = local.custom_dns_stacks

  depends_on = [google_project_service.dns]

  nuon_install_id = local.nuon_install_id
  name            = each.key
  gcp_project_id  = local.gcp_project_id
  gcp_region      = local.gcp_region
  gcp_network_id  = module.network.network_id
  parameters = merge(each.value.parameters, {
    for parameter_name, input_name in each.value.input_parameters :
    parameter_name => lookup(local.install_inputs, input_name, "")
  })
}

module "custom_kms" {
  source   = "./modules/kms"
  for_each = local.custom_kms_stacks

  depends_on = [google_project_service.cloud_kms]

  nuon_install_id = local.nuon_install_id
  name            = each.key
  gcp_project_id  = local.gcp_project_id
  gcp_region      = local.gcp_region
  parameters = merge(each.value.parameters, {
    for parameter_name, input_name in each.value.input_parameters :
    parameter_name => lookup(local.install_inputs, input_name, "")
  })
}

module "custom_service_account" {
  source   = "./modules/service_account"
  for_each = local.custom_service_account_stacks

  depends_on = [google_project_service.iam]

  nuon_install_id = local.nuon_install_id
  name            = each.key
  gcp_project_id  = local.gcp_project_id
  gcp_region      = local.gcp_region
  parameters = merge(each.value.parameters, {
    for parameter_name, input_name in each.value.input_parameters :
    parameter_name => lookup(local.install_inputs, input_name, "")
  })
}

locals {
  custom_stack_outputs = merge(
    { for name, stack in module.custom_bucket : name => { outputs = stack.outputs } },
    { for name, stack in module.custom_dns : name => { outputs = stack.outputs } },
    { for name, stack in module.custom_kms : name => { outputs = stack.outputs } },
    { for name, stack in module.custom_service_account : name => { outputs = stack.outputs } },
  )
}
