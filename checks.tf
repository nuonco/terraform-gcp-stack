# This module intentionally declares no `provider "google"` or `provider "stack"`
# block so that callers can compose it with count/for_each and pass in aliased
# providers. The tradeoff is that the google provider's project and region are
# set by the caller, independently of the target the Nuon control plane believes
# this install belongs to.
#
# A mismatch is quiet but damaging — resources would be created in one project
# or region while the outputs, the phone-home payload, and the Secret Manager
# resource names all reference another. This surfaces it at plan time, validated
# against the control plane rather than against another caller-supplied value.
#
# A `check` block warns without failing the apply, which is deliberate: an
# operator overriding the target on purpose should not be hard-blocked. The
# hard failure — neither source having a value at all — is a precondition on
# stack_phone_home.this instead.
data "google_client_config" "current" {}

check "gcp_project_matches_stack_config" {
  assert {
    # Skipped when the control plane has nothing recorded yet (a first apply):
    # there is no disagreement to report, only an absence.
    condition     = data.stack_config.this.gcp.project_id == "" || data.google_client_config.current.project == data.stack_config.this.gcp.project_id
    error_message = "The google provider is configured for project ${data.google_client_config.current.project}, but the Nuon control plane reports this install's project as ${data.stack_config.this.gcp.project_id}. Point the google provider at ${data.stack_config.this.gcp.project_id}."
  }
}

check "gcp_region_matches_stack_config" {
  assert {
    condition     = data.stack_config.this.gcp.region == "" || data.google_client_config.current.region == data.stack_config.this.gcp.region
    error_message = "The google provider is configured for region ${data.google_client_config.current.region}, but the Nuon control plane reports this install's region as ${data.stack_config.this.gcp.region}. Point the google provider at ${data.stack_config.this.gcp.region}."
  }
}
