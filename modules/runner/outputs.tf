output "instance_group_name" {
  value = google_compute_instance_group_manager.runner.name
}

output "instance_group_self_link" {
  value = google_compute_instance_group_manager.runner.instance_group
}

output "instance_template_self_link" {
  value = google_compute_instance_template.runner.self_link
}
