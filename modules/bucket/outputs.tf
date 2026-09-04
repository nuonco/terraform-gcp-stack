output "outputs" {
  value = {
    name      = google_storage_bucket.main.name
    url       = google_storage_bucket.main.url
    self_link = google_storage_bucket.main.self_link
  }
}
