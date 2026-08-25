# Minimal example

The simplest working configuration. To provision, give the provider a token.

```sh
export NUON_API_TOKEN=<your-token>
```

Then, apply.

```sh
terraform init && terraform apply
```

The module reads the install's project and region from the Nuon control plane. On a
first apply, before any phone home has recorded them, set them explicitly:

```hcl
module "gcp_stack" {
  source = "../../"

  install_id = var.install_id

  project_id = var.gcp_project_id
  region     = var.gcp_region
}
```
