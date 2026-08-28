# A dedicated custom-mode VPC with one subnet per tier. GCP subnets are
# regional, so unlike the AWS module there is one subnet per tier rather than
# one per availability zone; zonal redundancy comes from GCP's regional fabric.

resource "google_compute_network" "main" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

# private_ip_google_access lets instances without external IPs reach Google APIs
# (Secret Manager, Compute, Artifact Registry) directly rather than via the NAT.
resource "google_compute_subnetwork" "public" {
  name                     = "${var.prefix}-public-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.128.0.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.prefix}-private-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.128.1.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "runner" {
  name                     = "${var.prefix}-runner-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = "10.128.2.0/24"
  private_ip_google_access = true
}

resource "google_compute_router" "main" {
  name    = "${var.prefix}-router"
  region  = var.region
  network = google_compute_network.main.id
}

# A single Cloud NAT covering all three subnets. There is no public/private
# routing split as on AWS — "public" vs "private" is a naming convention
# downstream components consume, not a difference in egress path.
resource "google_compute_router_nat" "main" {
  name                               = "${var.prefix}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# 10.128.0.0/16 is a superset of the three /24s above, so this permits traffic
# between all tiers and nothing from the internet.
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.prefix}-allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.128.0.0/16"]
}

resource "google_compute_firewall" "allow_egress" {
  name      = "${var.prefix}-allow-egress"
  network   = google_compute_network.main.name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}
