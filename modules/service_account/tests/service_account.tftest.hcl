mock_provider "google" {}

run "defaults" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "workload"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
  }

  assert {
    condition     = startswith(google_service_account.main.account_id, "ncs-") && length(google_service_account.main.account_id) == 30
    error_message = "service account id must be deterministic and satisfy GCP length limits"
  }

  assert {
    condition     = google_service_account.main.display_name == "inst0000000000000000000000-workload"
    error_message = "display name must identify the install and custom stack"
  }

  assert {
    condition     = google_service_account.main.description == ""
    error_message = "description must be empty by default"
  }
}

run "parameter_overrides" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "workload"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      display_name = "Workload identity"
      description  = "Used by the application workload"
    }
  }

  assert {
    condition     = google_service_account.main.display_name == "Workload identity"
    error_message = "display_name parameter must be applied"
  }

  assert {
    condition     = google_service_account.main.description == "Used by the application workload"
    error_message = "description parameter must be applied"
  }
}

run "rejects_unknown_parameters" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "workload"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      typo = "true"
    }
  }

  expect_failures = [var.parameters]
}
