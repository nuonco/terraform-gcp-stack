terraform {
  required_version = ">= 1.9"

  required_providers {
    # Constrained to >= 6.0: the module is developed and tested against 6.x/7.x.
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    # >= 0.8.0: stack_version_id on both the data source and the phone-home
    # resource, without which a newly generated stack version produces no diff.
    stack = {
      source  = "nuonco/stack"
      version = ">= 0.8.0"
    }
  }
}
