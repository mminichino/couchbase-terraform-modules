provider "google" {
  project = var.gcp_project_id
  region  = var.regions[0]
}

module "multi_region" {
  source           = "../../../modules/gcp/multi_region"
  gcp_project_id   = var.gcp_project_id
  regions          = var.regions
  arbiter_region   = var.arbiter_region
  skip_zone        = var.skip_zone
  labels           = var.labels
  software_version = var.software_version
  nodes_per_region = var.nodes_per_region
  private_key_file = var.private_key_file
  public_key_file  = var.public_key_file
}
