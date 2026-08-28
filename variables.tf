##
## Module inputs.
##
## Almost everything this module needs is read from the Nuon control plane via
## the stack_config data source (see stack.tf). Only the values below cannot
## come from the API, or are deliberate caller-side overrides.
##

variable "install_id" {
  type        = string
  description = "Nuon install ID. Identifies which install's configuration to read; not a credential — the stack provider's api_token authorizes the read."

  validation {
    condition     = var.install_id != ""
    error_message = "install_id must be set; it identifies which install's configuration to fetch."
  }
}

##
## GCP target.
##
## Unlike AWS, where the control plane always holds the region, a GCP install can
## be created without a project or region: the first provision records them from
## the stack's phone home. So these read from the control plane by default and
## exist as overrides for the first apply, when it has nothing to serve. Once an
## install has provisioned once, leave them unset.
##

variable "project_id" {
  type        = string
  default     = ""
  description = "GCP project to provision the stack in. When empty, read from the Nuon control plane. Must resolve to a non-empty value from one source or the other."
}

variable "region" {
  type        = string
  default     = ""
  description = "GCP region to provision the stack in. When empty, read from the Nuon control plane. Must resolve to a non-empty value from one source or the other."

  # Catches a typo'd region before the google provider fails mid-apply with a
  # less obvious error. "" is allowed: it means "read from the control plane".
  validation {
    condition = var.region == "" || contains([
      "africa-south1",
      "asia-east1",
      "asia-east2",
      "asia-northeast1",
      "asia-northeast2",
      "asia-northeast3",
      "asia-south1",
      "asia-south2",
      "asia-southeast1",
      "asia-southeast2",
      "asia-southeast3",
      "australia-southeast1",
      "australia-southeast2",
      "europe-central2",
      "europe-north1",
      "europe-north2",
      "europe-southwest1",
      "europe-west1",
      "europe-west2",
      "europe-west3",
      "europe-west4",
      "europe-west6",
      "europe-west8",
      "europe-west9",
      "europe-west10",
      "europe-west12",
      "me-central1",
      "me-central2",
      "me-west1",
      "northamerica-northeast1",
      "northamerica-northeast2",
      "northamerica-south1",
      "southamerica-east1",
      "southamerica-west1",
      "us-central1",
      "us-east1",
      "us-east4",
      "us-east5",
      "us-south1",
      "us-west1",
      "us-west2",
      "us-west3",
      "us-west4",
    ], var.region)
    error_message = "region must be a valid GCP region (e.g. us-central1, europe-west1, asia-east1), or empty to read it from the Nuon control plane."
  }
}

##
## Runner.
##

variable "runner_enabled" {
  type        = bool
  default     = true
  description = "Whether to provision the runner module (instance template, managed instance group). Set to false to skip the runner and only create networking, IAM, and secrets."
}

variable "runner_machine_type" {
  type        = string
  default     = ""
  description = "Optional override for the runner's GCE machine type. When empty, the type is read from the Nuon app runner config, falling back to e2-medium."
}

##
## GKE.
##

variable "has_gke_node_pool" {
  type        = bool
  default     = true
  description = "Whether to create a least-privilege service account for GKE node pools. Ignored when gke_node_pool_sa_email names an existing one."
}

variable "gke_node_pool_sa_email" {
  type        = string
  default     = ""
  description = "Email of an existing GKE node pool service account. When set, no node-pool service account is created and this email is reported to Nuon instead."
}

##
## Inputs, secrets, and roles.
##

variable "inputs" {
  type        = map(string)
  default     = {}
  description = "Customer-facing install input values keyed by name. Layered over the values the Nuon control plane holds — any value set here wins — and reported back via phone home, where it becomes the install's current inputs. Keys must match inputs the app declares; unknown keys fail the plan, as does a required input that resolves to no value."
}

variable "secrets" {
  type = map(object({
    description = optional(string)
    required    = optional(bool)
    value       = optional(string)
  }))
  default     = {}
  sensitive   = true
  description = "Secret overrides keyed by name, layered over the stack_config data source. Any field set here wins. Use this to supply secret values the control plane does not hold. A secret the app declares required fails the plan if it resolves to no value, as does a key naming a secret the app does not declare."
}

variable "roles" {
  type        = map(bool)
  default     = {}
  description = "Per-role enable/disable overrides. Break-glass and custom roles are keyed by role name — the full served name or the name without its leading <install-id>- prefix — and a value set here wins over the control plane's enabled flag. The reserved keys provision, maintenance, and deprovision disable an operation role; disabling one prevents Nuon from performing that operation on the install until it is re-enabled and applied. Unknown keys fail the plan."
}
