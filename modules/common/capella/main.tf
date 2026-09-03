#

terraform {
  required_providers {
    couchbase-capella = {
      source  = "couchbasecloud/couchbase-capella"
      version = "~> 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "random_password" "db_password" {
  count   = var.db_password == null && var.db_password_secret == null ? 1 : 0
  length  = 16
  special = true
  override_special = "!@#$%^()_+-=[]{}|'"
}

data "aws_secretsmanager_secret_version" "db_password" {
  count     = var.db_password == null && var.db_password_secret != null ? 1 : 0
  secret_id = var.db_password_secret
}

locals {
  db_password = var.db_password != null ? var.db_password : (
    var.db_password_secret != null
    ? jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string)["key"]
    : random_password.db_password[0].result
  )
}

resource "couchbase-capella_cluster" "this" {
  organization_id = var.organization_id
  project_id      = var.project_id
  name            = var.cluster_name

  cloud_provider = {
    type   = var.cloud_provider
    region = var.region
    cidr   = var.cloud_provider_cidr
  }

  couchbase_server = {
    version = var.server_version
  }

  service_groups = [
    {
      node = {
        compute = {
          cpu = var.cpu
          ram = var.ram
        }
        disk = {
          storage = var.storage
          type    = var.disk_type
          iops    = var.iops
        }
      }
      num_of_nodes = var.num_of_nodes
      services     = var.services
    }
  ]

  availability = {
    type = var.availability_type
  }

  support = {
    plan     = var.support_plan
    timezone = var.support_timezone
  }
}

resource "couchbase-capella_allowlist" "this" {
  organization_id = var.organization_id
  project_id      = var.project_id
  cluster_id      = couchbase-capella_cluster.this.id
  cidr            = var.allowlist_cidr
  comment         = var.allowlist_comment
}

resource "couchbase-capella_database_credential" "this" {
  organization_id = var.organization_id
  project_id      = var.project_id
  cluster_id      = couchbase-capella_cluster.this.id
  name            = var.db_username
  password        = local.db_password

  access = [
    {
      privileges = ["data_reader", "data_writer"]
    }
  ]
}
