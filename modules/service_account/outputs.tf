output "outputs" {
  value = {
    email     = google_service_account.main.email
    unique_id = google_service_account.main.unique_id
    name      = google_service_account.main.name
  }
}
