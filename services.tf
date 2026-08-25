##
## Project API enablement.
##
## Every API the stack itself and the workloads Nuon deploys into this project
## need. None are disabled on destroy: the customer may have enabled them before
## Nuon existed, or be using them elsewhere in the project, so tearing an install
## down must not switch them off project-wide.
##

resource "google_project_service" "compute" {
  project            = local.gcp_project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager" {
  project            = local.gcp_project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_credentials" {
  project            = local.gcp_project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_resource_manager" {
  project            = local.gcp_project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  project            = local.gcp_project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "service_usage" {
  project            = local.gcp_project_id
  service            = "serviceusage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project            = local.gcp_project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dns" {
  project            = local.gcp_project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  project            = local.gcp_project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  project            = local.gcp_project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "service_networking" {
  project            = local.gcp_project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "certificate_manager" {
  project            = local.gcp_project_id
  service            = "certificatemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project            = local.gcp_project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}
