variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "regions" {
  type    = list(string)
  default = ["us-west3", "us-west4"]
}

variable "arbiter_region" {
  type    = string
  default = "us-south1"
}

variable "skip_zone" {
  description = "Zone names to exclude from node placement, such as us-central1-a."
  type        = list(string)
  default     = []
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

variable "nodes_per_region" {
  type    = number
  default = 3
}

variable "labels" {
  description = "Optional resource labels"
  type        = map(string)
  default     = {}
}
