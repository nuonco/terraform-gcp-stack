output "outputs" {
  value = {
    name            = google_dns_managed_zone.main.name
    name_servers    = join(",", google_dns_managed_zone.main.name_servers)
    managed_zone_id = tostring(google_dns_managed_zone.main.managed_zone_id)
  }
}
