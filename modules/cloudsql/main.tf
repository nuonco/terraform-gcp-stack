locals {
  instance_name_prefix = trimsuffix(substr(replace("${var.nuon_install_id}-${var.name}", "_", "-"), 0, 89), "-")
  instance_name        = "${local.instance_name_prefix}-${random_id.suffix.hex}"
  db_name              = lookup(var.parameters, "db_name", "postgres")
}

resource "random_id" "suffix" {
  byte_length = 4

  keepers = {
    install_id = var.nuon_install_id
    stack_name = var.name
  }
}

resource "google_sql_database_instance" "main" {
  project             = var.gcp_project_id
  name                = local.instance_name
  region              = var.gcp_region
  database_version    = lookup(var.parameters, "database_version", "POSTGRES_16")
  deletion_protection = lookup(var.parameters, "deletion_protection", "false") == "true"

  settings {
    tier              = lookup(var.parameters, "tier", "db-f1-micro")
    edition           = "ENTERPRISE"
    availability_type = lookup(var.parameters, "availability_type", "ZONAL")
    disk_size         = tonumber(lookup(var.parameters, "disk_size", "20"))
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.gcp_network_id
    }

    user_labels = {
      "nuon-install-id" = substr(var.nuon_install_id, 0, 63)
      stack             = substr(replace(var.name, "_", "-"), 0, 63)
    }
  }

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.instance_name))
      error_message = "custom Cloud SQL instance name ${local.instance_name} must use lowercase letters, numbers, or hyphens, start with a letter, and end with a letter or number."
    }
  }
}

resource "google_sql_database" "main" {
  count = local.db_name != "" && local.db_name != "postgres" ? 1 : 0

  project  = var.gcp_project_id
  name     = local.db_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "main" {
  project         = var.gcp_project_id
  name            = lookup(var.parameters, "db_user", "kitchensink")
  instance        = google_sql_database_instance.main.name
  password        = var.parameters["db_password"]
  deletion_policy = "ABANDON"
}
