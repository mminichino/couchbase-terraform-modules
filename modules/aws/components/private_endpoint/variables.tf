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
  description = "Capella cluster ID to connect via PrivateLink"
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC ID from the server module (application VPC)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR of the application VPC (used for endpoint security group ingress)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the interface VPC endpoint (typically module.server.subnet_id_list)"
  type        = list(string)
}

variable "region" {
  description = "AWS region of the application VPC (used when enabling private DNS)"
  type        = string
}

variable "name" {
  description = "Name prefix for AWS resources"
  type        = string
  default     = "capella-private-endpoint"
}

variable "enable_private_dns" {
  description = "Enable private DNS names on the VPC endpoint after Capella accepts it"
  type        = bool
  default     = true
}

variable "enable_xdcr_ports" {
  description = "Also allow Capella XDCR private endpoint ports (20091-20117) on the endpoint security group"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Optional tags for AWS resources"
  type        = map(string)
  default     = {}
}
