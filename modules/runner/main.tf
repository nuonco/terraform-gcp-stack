# The runner VM: an instance template plus a single-instance managed instance
# group. The root module gates this whole module on var.runner_enabled, so there
# is no count here.

resource "google_compute_instance_template" "runner" {
  name_prefix  = "${var.prefix}-runner-"
  machine_type = var.machine_type
  region       = var.region
  labels       = var.labels
  tags         = ["nuon-runner"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    disk_size_gb = 30
    disk_type    = "pd-balanced"
    boot         = true
  }

  # No external IP: egress goes through the network module's Cloud NAT, and the
  # runner needs no inbound connectivity.
  network_interface {
    subnetwork = var.runner_subnet_id
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  # The nuon_* metadata keys are the GCP mirror of the AWS module's instance
  # tags: the control plane reads nuon_runner_id back off the instance to verify
  # the runner's identity, which is why they are set as metadata and not only
  # exported inside the startup script.
  metadata = {
    nuon_runner_id      = var.runner_id
    nuon_runner_api_url = var.runner_api_url
    nuon_install_id     = var.nuon_install_id
    startup-script      = <<-EOT
      #!/bin/bash
      export NUON_RUNNER_ID=${var.runner_id}
      export NUON_RUNNER_API_URL=${var.runner_api_url}
      export NUON_RUNNER_API_TOKEN=${var.runner_api_token}
      export NUON_INSTALL_ID=${var.nuon_install_id}
      # Retry the whole bootstrap until it succeeds. Transient failures
      # (apt mirror sync, network blips, etc.) shouldn't leave the runner
      # permanently unprovisioned — init.sh is idempotent.
      until curl -fsSL ${var.runner_init_script_url} | bash; do
        echo "runner bootstrap failed, retrying in 30s"
        sleep 30
      done
    EOT
  }

  # name_prefix means each change creates a new template; the group below
  # references it, so the old one cannot be destroyed first.
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "runner" {
  name               = "${var.prefix}-runner"
  base_instance_name = "${var.prefix}-runner"
  zone               = "${var.region}-a"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.runner.self_link
  }

  # Replace rather than restart: the runner picks up its configuration from the
  # template's metadata at boot, so an in-place update would not apply it.
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
  }
}
