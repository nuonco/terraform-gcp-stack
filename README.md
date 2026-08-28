# terraform-gcp-stack

Terraform module for provisioning a [Nuon](https://nuon.co) install stack in GCP. It is meant to be applied by a customer against their own GCP project. It provisions a dedicated VPC network and a Compute Engine instance to host the Nuon runner. The runner polls the Nuon control plane for jobs and executes them locally by impersonating scoped service accounts.

## Usage

Import the Nuon Stack provider, then provide an install ID.
Provide the required inputs and secrets, and optionally enable or disable roles.

```hcl
provider "google" {
  project = "my-project"
  region  = "us-central1"
}

provider "stack" {}

module "gcp_stack" {
  source  = "nuonco/stack/gcp"
  version = "~> 1.0"

  install_id = var.install_id

  inputs = {
    machine_type = "e2-standard-4"
  }

  secrets = {
    license_key = { value = var.license_key }
  }

  roles = {
    "break-glass" = true
  }
}
```

The stack is provisioned into whatever project and region the `google` provider is configured with, and that target is reported back to Nuon by phone home. The `project_id` and `region` variables exist only to override it, which is rarely what you want: pointing them somewhere other than the provider provisions into one project while naming another in the outputs and phone-home payload.

## Architecture

![GCP install stack architecture](https://raw.githubusercontent.com/nuonco/terraform-gcp-stack/main/docs/architecture.svg)

## Resources

- **APIs** (`services.tf`) – Enables the project services the stack and its workloads need (Compute, IAM, Secret Manager, GKE, Cloud DNS, Artifact Registry, Cloud SQL, Storage, and more). None are disabled on destroy: the customer may have enabled them independently of Nuon.
- **VPC & subnets** (`modules/network`) – A dedicated custom-mode VPC with regional public, private, and runner subnets (all with Private Google Access enabled), a Cloud Router, and a Cloud NAT covering all subnets for outbound internet access.
- **Firewall rules** (`modules/network`) – All TCP/UDP/ICMP traffic allowed from `10.128.0.0/16` (a superset of the three subnets); all egress allowed to `0.0.0.0/0`. No inbound-from-internet rule exists.
- **Runner** (`modules/runner`) – An instance template + single-instance managed instance group (zone `<region>-a`, proactive replace on update) running Ubuntu 24.04 with a 30 GB pd-balanced boot disk and no external IP. The instance runs as the runner service account with `cloud-platform` scope. Set `runner_enabled = false` to skip these resources.
- **IAM** (`iam.tf`) –
  - **Runner service account** with a custom role granting `compute.instances.get`, so the control plane can verify the instance's identity during runner auth. The runner holds no standing workload permissions itself.
  - **Operation service accounts**, each granting the runner `roles/iam.serviceAccountTokenCreator` so it can impersonate them per-job. Permissions come from custom roles (one per named policy) and/or a predefined role (e.g. `roles/editor`). Each is created only if the app config grants it permissions:
    - **provision** – used by provision workflows and secret syncs
    - **maintenance** – used by everything else (the default)
    - **deprovision** – used by deprovision workflows
  - **Break-glass service accounts** – optional, created from the roles the control plane serves and gated on `enabled`.
  - **Custom service accounts** – optional app-operation roles, same shape and gating as break-glass roles.
  - **GKE node pool service account** – a least-privilege SA for GKE nodes (logging, monitoring, Artifact Registry read), created by default; pass `gke_node_pool_sa_email` to use an existing one instead, or set `has_gke_node_pool = false` to skip it.
- **Secrets** (`secrets.tf`) – Secret Manager entries named `<install-id>-<name>` for auto-generated secrets (63-char random values) and customer-provided secrets, plus an **empty** `<install-id>-telemetry-export-config` secret whose value the customer uploads out-of-band.
- **Phone home** (`phone_home.tf`) – A `stack_phone_home` resource that reports provisioning results and the effective install inputs back to Nuon. Its preconditions are where unknown or missing inputs, secrets, and roles fail the plan.

> [!NOTE]
> Because service account IDs are capped at 30 characters and don't support labels, the break-glass and custom SAs are named by a deterministic hash of the install ID and role name; the legible role name lives in the SA's display name and description.

## Network topology

| Network        | CIDR            | Scope    | Notes                                          |
| -------------- | --------------- | -------- | ---------------------------------------------- |
| VPC            | custom mode     | global   | no auto-created subnets                        |
| Public subnet  | `10.128.0.0/24` | regional | for internet-facing resources (load balancers) |
| Private subnet | `10.128.1.0/24` | regional | for workload infra (e.g. GKE)                  |
| Runner subnet  | `10.128.2.0/24` | regional | hosts the runner instance                      |

- Unlike AWS, GCP subnets are **regional**, so there is one subnet per tier rather than one per availability zone. Zonal redundancy comes from GCP's regional fabric, not from subnet layout.
- A single **Cloud NAT** (auto-allocated IPs) attached to the Cloud Router provides outbound internet access for **all** subnets — there is no public/private routing split; "public" vs "private" is a naming convention consumed by downstream components.
- All subnets have **Private Google Access** enabled, so instances without external IPs can still reach Google APIs (Secret Manager, Compute, Artifact Registry) directly.
- The network module gates its `runner_subnet_id` output on the Cloud NAT, so the runner instance cannot boot before its outbound route exists.
- The runner requires no inbound connectivity; for the outbound destinations it must reach, see [Runners](https://docs.nuon.co/concepts/runners).

## Runner authentication

On GCP, the Nuon runner authenticates with a **static API token**. GCP has no equivalent of AWS's signed Instance Identity Document, so the token is served by the control plane as part of the stack config and passed to the instance rather than exchanged for one at boot.

The bootstrap process is as follows.

1. The module reads `runner_api_token` from the `stack_config` data source; it never appears as a module variable.
1. The instance template's startup script exports `NUON_RUNNER_ID`, `NUON_RUNNER_API_URL`, `NUON_RUNNER_API_TOKEN`, and `NUON_INSTALL_ID`, then downloads and runs the init script, retrying until it succeeds (the script is idempotent).
1. The same non-secret values are also set as instance metadata (`nuon_runner_id`, `nuon_runner_api_url`, `nuon_install_id`) — the GCP mirror of the AWS module's instance tags.
1. The runner service account holds `compute.instances.get` so the control plane can independently read the instance's `nuon_runner_id` metadata when verifying the runner's identity.

> [!IMPORTANT]
> The token reaches the instance through the instance template's metadata, and is therefore stored in Terraform state. The state backend must be encrypted and access-controlled. This is the same constraint that applies to any secret value passed through this module.

## License

[MIT](./LICENSE)
