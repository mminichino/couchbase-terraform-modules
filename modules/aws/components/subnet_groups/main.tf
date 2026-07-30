#

data "aws_subnets" "vpc" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

locals {
  subnet_ids = data.aws_subnets.vpc.ids
  name       = var.id
}

resource "aws_db_subnet_group" "this" {
  name       = "db-${local.name}"
  subnet_ids = local.subnet_ids

  tags = merge(var.tags, {
    Name = "db-subnet-group-${local.name}"
  })
}

resource "aws_docdb_subnet_group" "this" {
  name       = "docdb-${local.name}"
  subnet_ids = local.subnet_ids

  tags = merge(var.tags, {
    Name = "docdb-subnet-group-${local.name}"
  })
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "elasticache-${local.name}"
  subnet_ids = local.subnet_ids

  tags = merge(var.tags, {
    Name = "elasticache-subnet-group-${local.name}"
  })
}

resource "aws_memorydb_subnet_group" "this" {
  name       = "memorydb-${local.name}"
  subnet_ids = local.subnet_ids

  tags = merge(var.tags, {
    Name = "memorydb-subnet-group-${local.name}"
  })
}

resource "aws_redshift_subnet_group" "this" {
  name       = "redshift-${local.name}"
  subnet_ids = local.subnet_ids

  tags = merge(var.tags, {
    Name = "redshift-subnet-group-${local.name}"
  })
}

resource "aws_dax_subnet_group" "this" {
  name       = "dax-${local.name}"
  subnet_ids = local.subnet_ids
}

resource "aws_neptune_subnet_group" "this" {
  name       = "neptune-${local.name}"
  subnet_ids = local.subnet_ids

  tags = merge(var.tags, {
    Name = "neptune-subnet-group-${local.name}"
  })
}
