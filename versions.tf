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
    # >= 0.5.0: this module reads config by install_id and reports via the
    # stack_phone_home resource's phone_home_url (neither exists in 0.3.x, where
    # phone_home_id was both the key and the credential), and it reads
    # gcp.project_id / gcp.region, which 0.4.x does not serve.
    stack = {
      source  = "nuonco/stack"
      version = ">= 0.5.0"
    }
  }
}
