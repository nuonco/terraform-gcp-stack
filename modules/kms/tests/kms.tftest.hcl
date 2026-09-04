mock_provider "google" {}

run "defaults" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
  }

  assert {
    condition     = google_kms_key_ring.main.location == "us-central1"
    error_message = "key ring location must default to the install region"
  }

  assert {
    condition     = google_kms_crypto_key.main.purpose == "ENCRYPT_DECRYPT"
    error_message = "crypto key purpose must default to ENCRYPT_DECRYPT"
  }

  assert {
    condition     = google_kms_crypto_key.main.rotation_period == "7776000s"
    error_message = "crypto key rotation must default to 90 days"
  }
}

run "parameter_overrides" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      location        = "global"
      rotation_period = "172800s"
    }
  }

  assert {
    condition     = google_kms_key_ring.main.location == "global"
    error_message = "location parameter must override the install region"
  }

  assert {
    condition     = google_kms_crypto_key.main.rotation_period == "172800s"
    error_message = "rotation period parameter must be applied"
  }
}

run "rejects_unknown_parameters" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      typo = "true"
    }
  }

  expect_failures = [var.parameters]
}

run "rejects_invalid_rotation_period" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "application"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    parameters = {
      rotation_period = "86400s"
    }
  }

  expect_failures = [var.parameters]
}
