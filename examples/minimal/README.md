# Minimal example

The simplest working configuration. To provision, give the provider a token.

```sh
export NUON_API_TOKEN=<your-token>
```

Then, apply.

```sh
terraform init && terraform apply
```

The module provisions into the project and region the `google` provider is
configured with — the same values this example passes to the provider block — so
nothing else needs setting.
