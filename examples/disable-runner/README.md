# Disable the runner

Customers can disable the runner by setting the `runner_enabled` attribute to `false`. This will tear down the runner's managed instance group, ensuring no runner instance is active, then report the runner is disabled to the Nuon control plane. In response, control plane will reject new workflows, cancel in-progress workflows, and pause scheduled workflows.

Networking, IAM, and secrets are still created, so the install can be resumed by flipping the flag back and re-applying.

```hcl
module "gcp_stack" {
  source = "../../"

  install_id = var.install_id

  runner_enabled = false
}
```
