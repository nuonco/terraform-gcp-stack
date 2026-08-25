variable "gcp_project_id" {
  type        = string
  description = "Project to configure the google provider with. Must match the project Nuon has recorded for this install."
}

variable "gcp_region" {
  type        = string
  description = "Region to configure the google provider with. Must match the region Nuon has recorded for this install."
}

variable "install_id" {
  type        = string
  description = "Nuon install ID. Identifies which install to configure; not a credential."
}
