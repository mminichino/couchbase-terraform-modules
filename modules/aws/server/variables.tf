#

variable "region" {
  type    = string
  default = "us-east-2"
}

# variable "dns_domain" {
#   type = string
# }
#
variable "public_key" {
  type = string
}

variable "private_key" {
  type = string
}
#
# variable "bucket" {
#   type = string
# }
#
variable "software_version" {
  type = string
}

variable "cluster_name" {
  description = "Couchbase cluster name"
  type        = string
  default     = "cbserver"
}

variable "data_path" {
  description = "Couchbase data path on each node"
  type        = string
  default     = "/cbdata"
}

variable "node_groups" {
  type = list(object({
    node_count   = number
    machine_type = string
    services     = list(string)
  }))
  default = [
    {
      node_count   = 3
      machine_type = "m5.xlarge"
      services     = ["data", "index", "query"]
    }
  ]
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
