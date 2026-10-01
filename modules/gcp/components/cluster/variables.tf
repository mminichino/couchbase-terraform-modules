#

variable "id" {
  description = "Deployment ID"
  type        = string
}

variable "cluster_name" {
  description = "Couchbase cluster name"
  type        = string
}

variable "data_path" {
  description = "Couchbase data path on each node"
  type        = string
}

variable "password" {
  type      = string
  default   = null
  sensitive = true
}

variable "password_secret" {
  description = "Name of the Secret Manager secret containing the cluster password (key: \"password\")"
  type        = string
  default     = null
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
    services     = list(string)
  }))
}

variable "root_volume_size" {
  description = "The root volume size in GB"
  default     = 64
  type        = number
}

variable "root_volume_type" {
  description = "The root volume type"
  default     = "pd-ssd"
  type        = string
}

variable "data_volume_size" {
  description = "The data volume size in GB"
  default     = 256
  type        = number
}

variable "data_volume_type" {
  description = "The data volume type"
  default     = "pd-ssd"
  type        = string
}

variable "private_key" {
  description = "Private key"
  type        = string
  sensitive   = true
}

variable "software_version" {
  description = "Couchbase Enterprise Software version"
  type        = string
}

variable "host_prep_version" {
  type    = string
  default = "2.0.0"
}

variable "cbctl_version" {
  description = "cbctl release tag installed from github.com/mminichino/cbctl"
  type        = string
  default     = "v0.4.0"
}

variable "admin_user" {
  type    = string
  default = "ubuntu"
}

variable "labels" {
  description = "Optional resource labels"
  type        = map(string)
  default     = {}
}
