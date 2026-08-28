terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    stack = {
      source  = "nuonco/stack"
      version = ">= 0.5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "stack" {
  api_url   = var.api_url
  api_token = var.api_token
}
