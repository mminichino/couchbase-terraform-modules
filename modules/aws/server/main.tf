#

provider "aws" {
  region = var.region
}

module "id" {
  source = "../components/id"
}

module "vpc" {
  source                = "../components/vpc"
  id                    = module.id.id
  cidr_block            = var.vpc_cidr
  tags                  = var.tags
}

module "key_pair" {
  source                  = "../components/key_pair"
  id                      = module.id.id
  private_key_secret_name = var.private_key_secret_name
  public_key_secret_name  = var.public_key_secret_name
  public_key_file         = var.public_key_file
  private_key_file        = var.private_key_file
  tags                    = var.tags
}

locals {
  private_key = module.key_pair.private_key
}

module "nodes" {
  source             = "../components/cluster"
  aws_subnet_id_list = module.vpc.subnet_id_list
  aws_vpc_cidr       = module.vpc.vpc_cidr
  aws_vpc_id         = module.vpc.vpc_id
  id                 = module.id.id
  cluster_name       = var.cluster_name
  data_path          = var.data_path
  password           = var.password
  password_secret    = var.password_secret
  private_key        = local.private_key
  software_version   = var.software_version
  aws_key_pair       = module.key_pair.key_name
  node_groups        = var.node_groups
  tags               = var.tags
}
