# Toggle roles

Customers can toggle the roles the runner impersonates using the `roles` attribute. This validates against the roles defined in the app config, ensuring they are using the correct names.

Two common use-cases for this are:

- Disabling the provision role once installation is complete, and the runner no longer needs the permissions it grants.
- Enabling a break-glass role, to provide elevated permissions to resolve incidents.

```hcl
module "gcp_stack" {
  source = "../../"

  install_id = var.install_id

  roles = {
    # provision is enabled by default, but can be disabled after installation is complete.
    provision = false

    # break glass roles are disabled by default, but can be enabled to grant elevated access.
    "break-glass" = true
  }
}
```

On GCP each role is a service account the runner holds `roles/iam.serviceAccountTokenCreator` on, so disabling one removes both the service account and the runner's ability to impersonate it.
