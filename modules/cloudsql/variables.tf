variable "nuon_install_id" {
  type = string
}

variable "name" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_network_id" {
  type = string

  validation {
    condition     = var.gcp_network_id != ""
    error_message = "gcp_network_id must be set."
  }
}

variable "db_password" {
  type      = string
  sensitive = true

  validation {
    condition     = var.db_password != ""
    error_message = "db_password must be set from the install db_password secret."
  }
}

variable "parameters" {
  type    = map(string)
  default = {}

  validation {
    condition = length(setsubtract(keys(var.parameters), [
      "availability_type",
      "database_version",
      "db_name",
      "db_user",
      "deletion_protection",
      "disk_size",
      "tier",
    ])) == 0
    error_message = "parameters supports only availability_type, database_version, db_name, db_user, deletion_protection, disk_size, and tier."
  }

  validation {
    condition     = lookup(var.parameters, "db_user", "kitchensink") != ""
    error_message = "parameters.db_user must not be empty."
  }

  validation {
    condition     = contains(["REGIONAL", "ZONAL"], lookup(var.parameters, "availability_type", "ZONAL"))
    error_message = "parameters.availability_type must be \"REGIONAL\" or \"ZONAL\"."
  }

  validation {
    condition     = contains(["true", "false"], lookup(var.parameters, "deletion_protection", "false"))
    error_message = "parameters.deletion_protection must be \"true\" or \"false\"."
  }

  validation {
    condition = try(
      tonumber(lookup(var.parameters, "disk_size", "20")) >= 10 &&
      floor(tonumber(lookup(var.parameters, "disk_size", "20"))) == tonumber(lookup(var.parameters, "disk_size", "20")),
      false,
    )
    error_message = "parameters.disk_size must be a whole number of at least 10."
  }
}
