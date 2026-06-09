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

variable "node_groups" {
  type = list(object({
    node_count   = number
    machine_type = string
  }))
  default = [
    {
      node_count   = 3
      machine_type = "m5.xlarge"
    }
  ]
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
