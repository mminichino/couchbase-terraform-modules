variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "regions" {
  description = "Two regions that each host a Couchbase server group of service nodes."
  type        = list(string)
  default     = ["us-west3", "us-west4"]

  validation {
    condition     = length(var.regions) == 2 && length(distinct(var.regions)) == 2
    error_message = "regions must contain exactly two distinct GCP regions."
  }
}

variable "arbiter_region" {
  description = "Third region for the single arbiter node. Must be different from both service regions."
  type        = string
  default     = "us-south1"
}

variable "skip_zone" {
  description = "Zone names to exclude from node placement, such as us-central1-a."
  type        = list(string)
  default     = []
}

variable "subnet_cidrs" {
  description = "Subnet CIDR for each service region, in the same order as regions. CIDRs must not overlap the arbiter subnet."
  type        = list(string)
  default     = ["10.81.0.0/16", "10.82.0.0/16"]

  validation {
    condition     = length(var.subnet_cidrs) == 2 && alltrue([for cidr in var.subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "subnet_cidrs must contain two CIDR blocks, one for each service region."
  }
}

variable "arbiter_subnet_cidr" {
  description = "Subnet CIDR for the arbiter region."
  type        = string
  default     = "10.83.0.0/16"

  validation {
    condition     = can(cidrhost(var.arbiter_subnet_cidr, 0))
    error_message = "arbiter_subnet_cidr must be a CIDR block."
  }
}

variable "public_key_secret_name" {
  description = "Name of the Secret Manager secret containing the SSH public key (JSON key: \"key\")"
  type        = string
  default     = null
}

variable "private_key_secret_name" {
  description = "Name of the Secret Manager secret containing the SSH private key (JSON key: \"key\")"
  type        = string
  default     = null
}

variable "public_key_file" {
  description = "SSH public key filename in ~/.ssh (e.g. id_rsa.pub). Used instead of public_key_secret_name when set."
  type        = string
  default     = null
}

variable "private_key_file" {
  description = "SSH private key filename in ~/.ssh (e.g. id_rsa). Used instead of private_key_secret_name when set."
  type        = string
  default     = null
}

variable "password" {
  description = "Couchbase cluster admin password"
  type        = string
  default     = null
  sensitive   = true
}

variable "password_secret" {
  description = "Name of the Secret Manager secret containing the cluster password (JSON key: \"password\"). Used when password is not set."
  type        = string
  default     = null
}

variable "software_version" {
  description = "Couchbase Enterprise version. Arbiter nodes require 7.6 or newer."
  type        = string

  validation {
    condition = try(
      tonumber(split(".", var.software_version)[0]) > 7 ||
      (tonumber(split(".", var.software_version)[0]) == 7 && tonumber(split(".", var.software_version)[1]) >= 6),
      false
    )
    error_message = "software_version must be Couchbase Server 7.6 or newer so the arbiter node can join."
  }
}

variable "cluster_name" {
  description = "Couchbase cluster name"
  type        = string
  default     = "cbserver"
}

variable "data_path" {
  description = "Couchbase data path on each service node"
  type        = string
  default     = "/cbdata"
}

variable "nodes_per_region" {
  description = "Service nodes in each region. Must be a multiple of 3 so an expansion adds one node in each of the region's first three usable zones."
  type        = number
  default     = 3

  validation {
    condition     = var.nodes_per_region >= 3 && var.nodes_per_region % 3 == 0
    error_message = "nodes_per_region must be at least 3 and a multiple of 3."
  }
}

variable "machine_type" {
  description = "Machine type for service nodes"
  type        = string
  default     = "n4-standard-8"
}

variable "arbiter_machine_type" {
  description = "Machine type for the arbiter node. The arbiter runs only the Cluster Manager."
  type        = string
  default     = "n2-standard-4"
}

variable "services" {
  description = "Couchbase services on each service node"
  type        = list(string)
  default     = ["data", "index", "query"]

  validation {
    condition     = length(var.services) > 0
    error_message = "At least one service is required on service nodes."
  }
}

variable "data_volume_size" {
  description = "The data volume size in GB for service nodes"
  default     = 256
  type        = number
}

variable "arbiter_data_volume_size" {
  description = "Data volume size in GB for the arbiter. Attached so host preparation sees the same device layout as service nodes."
  default     = 32
  type        = number
}

variable "arbiter_data_volume_type" {
  description = "Data disk type for the arbiter. N2 supports Persistent Disk types such as pd-ssd, pd-balanced, and pd-standard."
  default     = "pd-ssd"
  type        = string
}

variable "arbiter_root_volume_type" {
  description = "Boot disk type for the arbiter. N2 boot disks use Persistent Disk, such as pd-ssd, pd-balanced, or pd-standard."
  default     = "pd-ssd"
  type        = string
}

variable "data_volume_type" {
  description = "Data disk type. N4 supports only Hyperdisk: hyperdisk-balanced, hyperdisk-balanced-high-availability, or hyperdisk-throughput."
  default     = "hyperdisk-balanced"
  type        = string
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

variable "host_prep_version" {
  description = "host-prep-lib release installed on each node"
  type        = string
  default     = "2.0.0"
}

variable "cbctl_version" {
  description = "cbctl release tag installed from github.com/mminichino/cbctl. Arbiter join requires v0.5.0 or newer."
  type        = string
  default     = "v0.5.0"
}

variable "labels" {
  description = "Optional resource labels"
  type        = map(string)
  default     = {}
}
