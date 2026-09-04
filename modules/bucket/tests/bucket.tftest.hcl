mock_provider "google" {}

run "defaults" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "assets"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
  }

  assert {
    condition     = google_storage_bucket.main.name == "inst0000000000000000000000-assets"
    error_message = "bucket name must remain stable for an install and stack name"
  }

  assert {
    condition     = google_storage_bucket.main.location == "us-central1"
    error_message = "bucket location must default to the install region"
  }

  assert {
    condition     = google_storage_bucket.main.force_destroy == false
    error_message = "bucket contents must be protected by default"
  }
}

run "parameter_overrides" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "assets"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      force_destroy = "true"
      location      = "US"
      versioning    = "true"
    }
  }

  assert {
    condition     = google_storage_bucket.main.location == "US"
    error_message = "location parameter must override the install region"
  }

  assert {
    condition     = google_storage_bucket.main.force_destroy == true
    error_message = "force_destroy parameter must be applied"
  }

  assert {
    condition     = google_storage_bucket.main.versioning[0].enabled == true
    error_message = "versioning parameter must enable bucket versioning"
  }
}

run "rejects_unknown_parameters" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "assets"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      typo = "true"
    }
  }

  expect_failures = [var.parameters]
}
