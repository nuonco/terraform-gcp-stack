variable "prefix" {
  type        = string
  description = "Name prefix for every resource; the Nuon install ID."
}

variable "region" {
  type        = string
  description = "GCP region. The managed instance group is zonal, placed in <region>-a."
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels applied to the instance template."
}

variable "machine_type" {
  type        = string
  description = "GCE machine type for the runner instance."
}

variable "runner_subnet_id" {
  type        = string
  description = "Subnetwork to attach the runner's network interface to."
}

variable "service_account_email" {
  type        = string
  description = "Service account the runner instance runs as."
}

variable "nuon_install_id" {
  type        = string
  description = "Nuon install ID, passed to the runner and mirrored in instance metadata."
}

variable "runner_id" {
  type        = string
  description = "Nuon runner ID. Also set as the nuon_runner_id metadata key, which the control plane reads to verify the instance's identity."
}

variable "runner_api_url" {
  type        = string
  description = "Base URL of the Nuon runner API."
}

variable "runner_api_token" {
  type        = string
  sensitive   = true
  description = "Static token the runner authenticates to the Nuon API with. Unlike AWS, GCP has no instance-identity exchange, so this is passed to the instance."
}

variable "runner_init_script_url" {
  type        = string
  description = "URL of the runner bootstrap script the startup script fetches and runs."
}
