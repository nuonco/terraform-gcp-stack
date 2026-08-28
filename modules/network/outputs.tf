output "network_name" {
  value = google_compute_network.main.name
}

output "network_id" {
  value = google_compute_network.main.id
}

output "public_subnet_name" {
  value = google_compute_subnetwork.public.name
}

output "private_subnet_name" {
  value = google_compute_subnetwork.private.name
}

# Gated on the NAT so the runner instance cannot boot before its outbound route
# exists: the startup script needs egress immediately, and nothing else orders
# the NAT ahead of the instance group.
output "runner_subnet_name" {
  value      = google_compute_subnetwork.runner.name
  depends_on = [google_compute_router_nat.main]
}

output "runner_subnet_id" {
  value      = google_compute_subnetwork.runner.id
  depends_on = [google_compute_router_nat.main]
}
