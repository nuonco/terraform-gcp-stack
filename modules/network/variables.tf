variable "prefix" {
  type        = string
  description = "Name prefix for every resource; the Nuon install ID."
}

variable "region" {
  type        = string
  description = "GCP region for the subnets, router, and NAT."
}
