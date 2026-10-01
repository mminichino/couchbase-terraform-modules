#

data "google_compute_zones" "available" {
  project = var.gcp_project_id
  region  = var.gcp_region
  status  = "UP"
}

locals {
  zones = sort(data.google_compute_zones.available.names)
}

resource "google_compute_network" "vpc" {
  name                    = "vpc-${var.id}"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
  description             = "Couchbase VPC ${var.id}"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-${var.id}"
  ip_cidr_range = var.cidr_block
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  project       = var.gcp_project_id
}
