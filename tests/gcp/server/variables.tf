#

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "public_key_file" {
  type = string
}

variable "private_key_file" {
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

variable "labels" {
  description = "Optional resource labels"
  type        = map(string)
  default     = {}
}
