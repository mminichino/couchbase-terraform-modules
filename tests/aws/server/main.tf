#

provider "aws" {
  region = var.region
}

module "server" {
  source                  = "../../../modules/aws/server"
  tags                    = var.tags
  software_version        = var.software_version
  node_groups             = var.nodes
  private_key_secret_name = var.private_key_secret_name
  public_key_secret_name  = var.public_key_secret_name
}
