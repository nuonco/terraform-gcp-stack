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
    condition     = length(setsubtract(keys(var.parameters), ["description", "display_name"])) == 0
    error_message = "parameters supports only description and display_name."
  }
}
