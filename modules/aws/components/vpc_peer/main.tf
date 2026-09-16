# Peer an application VPC (modules/aws/server) to a Capella cluster (modules/common/capella).
#
# Flow:
# 1. Create Capella network peer (Capella initiates the AWS VPC peering request)
# 2. Accept the peering connection in the application account
# 3. Associate the application VPC with Capella's private hosted zone (DNS)
# 4. Add routes for Capella's CIDR via the peering connection

data "aws_caller_identity" "current" {}

data "aws_route_tables" "vpc" {
  count  = length(var.route_table_ids) == 0 ? 1 : 0
  vpc_id = var.vpc_id
}

data "aws_vpc_peering_connection" "this" {
  id = aws_vpc_peering_connection_accepter.this.id
}

locals {
  account_id = coalesce(var.account_id, data.aws_caller_identity.current.account_id)

  peering_connection_id = couchbase-capella_network_peer.this.provider_config.aws_config.provider_id

  associate_command = one([
    for cmd in couchbase-capella_network_peer.this.commands : cmd
    if can(regex("associate-vpc-with-hosted-zone", cmd))
  ])

  # regexall returns a list of matches; each match with one capture group is a list of one string.
  hosted_zone_id = regexall("--hosted-zone-id=([A-Z0-9]+)", local.associate_command)[0][0]

  # Use a list (not a set) so routes can use count. for_each requires known keys at
  # plan time; route table IDs from a sibling module are often unknown until apply.
  route_table_ids = length(var.route_table_ids) > 0 ? var.route_table_ids : data.aws_route_tables.vpc[0].ids

  # Capella is the peering requester; cidr_block is RequesterVpcInfo.
  capella_cidr = coalesce(var.capella_cidr, data.aws_vpc_peering_connection.this.cidr_block)
}

resource "couchbase-capella_network_peer" "this" {
  organization_id = var.organization_id
  project_id      = var.project_id
  cluster_id      = var.cluster_id
  name            = var.name
  provider_type   = "aws"

  provider_config = {
    aws_config = {
      account_id = local.account_id
      vpc_id     = var.vpc_id
      cidr       = var.vpc_cidr
      region     = var.region
    }
  }
}

resource "aws_vpc_peering_connection_accepter" "this" {
  vpc_peering_connection_id = local.peering_connection_id
  auto_accept               = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_route53_zone_association" "capella" {
  zone_id    = local.hosted_zone_id
  vpc_id     = var.vpc_id
  vpc_region = var.region

  depends_on = [aws_vpc_peering_connection_accepter.this]
}

resource "aws_route" "capella" {
  count = length(local.route_table_ids)

  route_table_id            = local.route_table_ids[count.index]
  destination_cidr_block    = local.capella_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  depends_on = [aws_vpc_peering_connection_accepter.this]
}
