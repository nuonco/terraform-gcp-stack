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
  type    = string
  default = ""
}

variable "parameters" {
  type    = map(string)
  default = {}

  validation {
    condition     = length(setsubtract(keys(var.parameters), ["description", "dns_name", "force_destroy", "visibility"])) == 0
    error_message = "parameters supports only description, dns_name, force_destroy, and visibility."
  }

  validation {
    condition     = lookup(var.parameters, "dns_name", "") != ""
    error_message = "parameters.dns_name must be set."
  }

  validation {
    condition     = endswith(lookup(var.parameters, "dns_name", "."), ".")
    error_message = "parameters.dns_name must end with a trailing dot, for example \"app.example.com.\"."
  }

  validation {
    condition     = contains(["private", "public"], lookup(var.parameters, "visibility", "public"))
    error_message = "parameters.visibility must be \"private\" or \"public\"."
  }

  validation {
    condition     = contains(["true", "false"], lookup(var.parameters, "force_destroy", "false"))
    error_message = "parameters.force_destroy must be \"true\" or \"false\"."
  }
}
