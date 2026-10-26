#

variable "id" {
  description = "Deployment ID"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_network" {
  description = "VPC network name or self link"
  type        = string
}

variable "gcp_vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "gcp_subnet" {
  description = "Subnet self link"
  type        = string
}

variable "zones" {
  description = "Zones used to spread nodes"
  type        = list(string)
}

variable "public_key" {
  description = "SSH public key installed for the ubuntu user"
  type        = string
}

variable "node_groups" {
  description = "Node group specifications"
  type = list(object({
    node_count   = number
    machine_type = string
  }))
  default = [
    {
      node_count   = 1
      machine_type = "n4-standard-8"
    }
  ]
}

variable "root_volume_size" {
  description = "The root volume size in GB"
  default     = 64
  type        = number
}

variable "root_volume_type" {
  description = "Boot disk type. N4 boot disks must be hyperdisk-balanced or hyperdisk-balanced-high-availability."
  default     = "hyperdisk-balanced"
  type        = string
}

variable "data_volume_type" {
  description = "Data disk type. N4 supports only Hyperdisk: hyperdisk-balanced, hyperdisk-balanced-high-availability, or hyperdisk-throughput."
  default     = "hyperdisk-balanced"
  type        = string
}

variable "data_volume_size" {
  description = "The data volume size"
  default     = 256
  type        = number
}

variable "private_key" {
  description = "Private key"
  type        = string
  sensitive   = true
}

variable "host_prep_version" {
  type    = string
  default = "2.0.0a1"
}

variable "labels" {
  description = "Optional resource labels"
  type        = map(string)
  default     = {}
}
