#

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

module "server" {
  source                  = "../../../modules/gcp/server"
  gcp_project_id          = var.gcp_project_id
  gcp_region              = var.gcp_region
  labels                  = var.labels
  software_version        = var.software_version
  node_groups             = var.nodes
  private_key_file        = var.private_key_file
  public_key_file         = var.public_key_file
}
