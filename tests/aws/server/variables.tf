#

variable "region" {
  type    = string
  default = "us-east-2"
}

# variable "ec2_role" {
#   type = string
# }
#
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

variable "nodes" {
  type = list(object({
    node_count   = number
    machine_type = string
    services     = list(string)
  }))
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
