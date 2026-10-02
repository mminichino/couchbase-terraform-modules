#

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

module "id" {
  source = "../components/id"
}

module "vpc" {
  source         = "../components/vpc"
  id             = module.id.id
  cidr_block     = var.vpc_cidr
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
}

module "key_pair" {
  source                  = "../components/key_pair"
  gcp_project_id          = var.gcp_project_id
  private_key_secret_name = var.private_key_secret_name
  public_key_secret_name  = var.public_key_secret_name
  public_key_file         = var.public_key_file
  private_key_file        = var.private_key_file
}

locals {
  private_key = module.key_pair.private_key
}

module "nodes" {
  source           = "../components/cluster"
  gcp_network      = module.vpc.vpc_self_link
  gcp_subnet       = module.vpc.subnet_self_link
  gcp_vpc_cidr     = module.vpc.vpc_cidr
  gcp_project_id   = var.gcp_project_id
  zones            = module.vpc.zones
  id               = module.id.id
  cluster_name     = var.cluster_name
  data_path        = var.data_path
  password         = var.password
  password_secret  = var.password_secret
  private_key      = local.private_key
  public_key       = module.key_pair.public_key
  software_version = var.software_version
  node_groups      = var.node_groups
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type
  data_volume_size = var.data_volume_size
  data_volume_type = var.data_volume_type
  labels           = var.labels
}
