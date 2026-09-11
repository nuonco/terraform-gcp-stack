locals {
  telemetry_ingress_enabled = var.enable_telemetry_ingress && var.runner_enabled
  telemetry_endpoint        = local.telemetry_ingress_enabled ? "http://${google_compute_forwarding_rule.telemetry[0].ip_address}:4318" : ""
}

resource "google_compute_address" "telemetry" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name         = "${local.prefix}-telemetry"
  region       = local.gcp_region
  address_type = "INTERNAL"
  subnetwork   = module.network.runner_subnet_id
  labels       = local.labels
}

resource "google_compute_region_health_check" "telemetry" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name   = "${local.prefix}-telemetry"
  region = local.gcp_region

  tcp_health_check {
    port = 4318
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_region_backend_service" "telemetry" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name                  = "${local.prefix}-telemetry"
  region                = local.gcp_region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.telemetry[0].id]

  backend {
    group          = module.runner[0].instance_group_self_link
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "telemetry" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name                  = "${local.prefix}-telemetry"
  region                = local.gcp_region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  ports                 = ["4318"]
  allow_global_access   = false
  network               = module.network.network_id
  subnetwork            = module.network.runner_subnet_id
  ip_address            = google_compute_address.telemetry[0].address
  backend_service       = google_compute_region_backend_service.telemetry[0].id
  labels                = local.labels
}

resource "google_compute_firewall" "telemetry_health_check" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name          = "${local.prefix}-telemetry-health-check"
  network       = module.network.network_id
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["nuon-runner"]

  allow {
    protocol = "tcp"
    ports    = ["4318"]
  }
}
