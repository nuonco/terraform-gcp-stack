mock_provider "google" {}

run "defaults" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    parameters = {
      dns_name = "app.example.com."
    }
  }

  assert {
    condition     = google_dns_managed_zone.main.name == "inst0000000000000000000000-application"
    error_message = "managed zone name must remain stable for an install and stack name"
  }

  assert {
    condition     = google_dns_managed_zone.main.description == "inst0000000000000000000000-application managed zone"
    error_message = "managed zone description must have a non-empty default"
  }

  assert {
    condition     = google_dns_managed_zone.main.visibility == "public"
    error_message = "managed zone visibility must default to public"
  }

  assert {
    condition     = google_dns_managed_zone.main.force_destroy == false
    error_message = "managed zone records must be protected by default"
  }
}

run "parameter_overrides" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    parameters = {
      description   = "Application zone"
      dns_name      = "app.example.com."
      force_destroy = "true"
      visibility    = "private"
    }
  }

  assert {
    condition     = google_dns_managed_zone.main.description == "Application zone"
    error_message = "description parameter must be applied"
  }

  assert {
    condition     = google_dns_managed_zone.main.force_destroy == true
    error_message = "force_destroy parameter must be applied"
  }

  assert {
    condition     = one(google_dns_managed_zone.main.private_visibility_config[0].networks).network_url == "projects/example-project/global/networks/install"
    error_message = "private zones must attach to the install network"
  }
}

run "rejects_missing_dns_name" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
  }

  expect_failures = [var.parameters]
}

run "rejects_unknown_parameters" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      dns_name = "app.example.com."
      typo     = "true"
    }
  }

  expect_failures = [var.parameters]
}

run "rejects_dns_name_without_trailing_dot" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      dns_name = "app.example.com"
    }
  }

  expect_failures = [var.parameters]
}

run "rejects_private_zone_without_network" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      dns_name   = "app.example.com."
      visibility = "private"
    }
  }

  expect_failures = [google_dns_managed_zone.main]
}
