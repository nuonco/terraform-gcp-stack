mock_provider "google" {}
mock_provider "random" {}

run "defaults" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "cloudsql_instance"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    db_password     = "test-password"
  }

  assert {
    condition     = local.instance_name_prefix == "inst0000000000000000000000-cloudsql-instance"
    error_message = "instance name must replace underscores with hyphens"
  }

  assert {
    condition     = random_id.suffix.byte_length == 4
    error_message = "instance name suffix must contain eight hexadecimal characters"
  }

  assert {
    condition     = random_id.suffix.keepers.stack_name == "cloudsql_instance"
    error_message = "instance name suffix must remain stable for the stack name"
  }

  assert {
    condition     = google_sql_database_instance.main.database_version == "POSTGRES_16"
    error_message = "database version must default to PostgreSQL 16"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].tier == "db-f1-micro"
    error_message = "tier must default to db-f1-micro"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].availability_type == "ZONAL"
    error_message = "availability type must default to ZONAL"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].disk_size == 20
    error_message = "disk size must default to 20 GB"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].edition == "ENTERPRISE"
    error_message = "database edition must be ENTERPRISE"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].disk_type == "PD_SSD"
    error_message = "database disk type must be PD_SSD"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].ipv4_enabled == false
    error_message = "public IPv4 must be disabled"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].private_network == "projects/example-project/global/networks/install"
    error_message = "instance must attach to the install network"
  }

  assert {
    condition     = google_sql_database_instance.main.deletion_protection == false
    error_message = "deletion protection must default to false"
  }

  assert {
    condition     = length(google_sql_database.main) == 0
    error_message = "default postgres database must not be created"
  }

  assert {
    condition     = google_sql_user.main.name == "kitchensink"
    error_message = "database user must default to kitchensink"
  }

  assert {
    condition     = google_sql_user.main.deletion_policy == "ABANDON"
    error_message = "database user must be abandoned on destroy"
  }

  assert {
    condition     = output.outputs.DBPort == "5432" && output.outputs.DBUser == "kitchensink" && output.outputs.DBName == "postgres"
    error_message = "database connection outputs must use the expected defaults"
  }
}

run "parameter_overrides" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "database"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    db_password     = "test-password"
    parameters = {
      availability_type   = "REGIONAL"
      database_version    = "POSTGRES_15"
      db_name             = ""
      db_user             = "app"
      deletion_protection = "true"
      disk_size           = "50"
      tier                = "db-custom-2-7680"
    }
  }

  assert {
    condition     = google_sql_database_instance.main.database_version == "POSTGRES_15"
    error_message = "database version parameter must be applied"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].tier == "db-custom-2-7680"
    error_message = "tier parameter must be applied"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].availability_type == "REGIONAL"
    error_message = "availability type parameter must be applied"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].disk_size == 50
    error_message = "disk size parameter must be applied"
  }

  assert {
    condition     = google_sql_database_instance.main.deletion_protection == true
    error_message = "deletion protection parameter must be applied"
  }

  assert {
    condition     = length(google_sql_database.main) == 0
    error_message = "empty database name must skip the database resource"
  }

  assert {
    condition     = google_sql_user.main.name == "app"
    error_message = "database user parameter must be applied"
  }
}

run "custom_database" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "database"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    db_password     = "test-password"
    parameters = {
      db_name = "app"
    }
  }

  assert {
    condition     = google_sql_database.main[0].name == "app"
    error_message = "custom database name must create the database resource"
  }

  assert {
    condition     = output.outputs.DBName == "app"
    error_message = "custom database name must be exposed on outputs"
  }
}

run "rejects_missing_password" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "database"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    db_password     = ""
  }

  expect_failures = [var.db_password]
}

run "rejects_unknown_parameters" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "database"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    db_password     = "test-password"
    parameters = {
      typo = "true"
    }
  }

  expect_failures = [var.parameters]
}

run "rejects_empty_network" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "database"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = ""
    db_password     = "test-password"
  }

  expect_failures = [var.gcp_network_id]
}

run "rejects_invalid_disk_size" {
  command = plan

  variables {
    nuon_install_id = "inst0000000000000000000000"
    name            = "database"
    gcp_project_id  = "example-project"
    gcp_region      = "us-central1"
    gcp_network_id  = "projects/example-project/global/networks/install"
    db_password     = "test-password"
    parameters = {
      disk_size = "small"
    }
  }

  expect_failures = [var.parameters]
}
