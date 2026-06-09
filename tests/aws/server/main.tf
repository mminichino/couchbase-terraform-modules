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
}
