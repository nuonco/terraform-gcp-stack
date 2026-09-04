output "outputs" {
  value = {
    id       = google_kms_crypto_key.main.id
    key_ring = google_kms_key_ring.main.id
    name     = google_kms_crypto_key.main.name
  }
}
