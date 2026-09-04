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

variable "parameters" {
  type    = map(string)
  default = {}

  validation {
    condition     = length(setsubtract(keys(var.parameters), ["force_destroy", "location", "versioning"])) == 0
    error_message = "parameters supports only force_destroy, location, and versioning."
  }

  validation {
    condition     = contains(["true", "false"], lookup(var.parameters, "force_destroy", "false"))
    error_message = "parameters.force_destroy must be \"true\" or \"false\"."
  }

  validation {
    condition     = contains(["true", "false"], lookup(var.parameters, "versioning", "false"))
    error_message = "parameters.versioning must be \"true\" or \"false\"."
  }
}
