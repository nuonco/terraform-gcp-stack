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
    condition     = length(setsubtract(keys(var.parameters), ["location", "rotation_period"])) == 0
    error_message = "parameters supports only location and rotation_period."
  }

  validation {
    condition = (
      can(regex("^[0-9]+s$", lookup(var.parameters, "rotation_period", "7776000s"))) &&
      try(tonumber(trimsuffix(lookup(var.parameters, "rotation_period", "7776000s"), "s")) > 86400, false)
    )
    error_message = "parameters.rotation_period must be an integer number of seconds ending in s and greater than 86400s."
  }
}
