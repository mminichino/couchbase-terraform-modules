#

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "public_key_secret_name" {
  type = string
}

variable "private_key_secret_name" {
  type = string
}

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

variable "clients" {
  type = list(object({
    node_count   = number
    machine_type = string
  }))
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
