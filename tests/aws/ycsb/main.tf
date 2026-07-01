#

provider "aws" {
  region = var.region
}

module "server" {
  source           = "../../../modules/aws/server"
  tags             = var.tags
  private_key      = var.private_key
  public_key       = var.public_key
  software_version = var.software_version
  node_groups      = var.nodes
}

module "client" {
  source             = "../../../modules/aws/components/client"
  tags               = var.tags
  private_key        = var.private_key
  node_groups        = var.clients
  aws_key_pair       = module.server.aws_key_pair
  aws_subnet_id_list = module.server.subnet_id_list
  aws_vpc_cidr       = module.server.vpc_cidr
  aws_vpc_id         = module.server.vpc_id
  id                 = module.server.id
}
