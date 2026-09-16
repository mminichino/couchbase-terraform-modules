#

variable "organization_id" {
  description = "Couchbase Capella organization ID"
  type        = string
}

variable "project_id" {
  description = "Couchbase Capella project ID"
  type        = string
}

variable "cluster_id" {
  description = "Capella cluster ID to peer with"
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC ID from the server module (application VPC)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR of the application VPC (must not overlap Capella CIDR)"
  type        = string
}

variable "region" {
  description = "AWS region of the application VPC"
  type        = string
}

variable "name" {
  description = "Name of the Capella network peering relationship"
  type        = string
  default     = "aws-vpc-peer"
}

variable "account_id" {
  description = "AWS account ID owning the application VPC. Defaults to the current caller identity."
  type        = string
  default     = null
}

variable "capella_cidr" {
  description = "Capella cluster VPC CIDR (RequesterVpcInfo). If null, derived from the accepted peering connection."
  type        = string
  default     = null
}

variable "route_table_ids" {
  description = "Route table IDs to update with a route to Capella. If empty, all route tables in the VPC are updated."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Optional tags for AWS resources that support them"
  type        = map(string)
  default     = {}
}
