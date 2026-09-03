#

variable "organization_id" {
  description = "Couchbase Capella organization ID"
  type        = string
}

variable "project_id" {
  description = "Couchbase Capella project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Capella cluster"
  type        = string
  default     = "cbdb"
}

variable "cloud_provider" {
  description = "Cloud provider type (aws, gcp, azure)"
  type        = string
  default     = "aws"
}

variable "cloud_provider_cidr" {
  description = "CIDR block for the cloud provider VPC"
  type        = string
  default     = "10.200.250.0/23"
}

variable "region" {
  description = "Cloud provider region"
  type        = string
  default     = "us-east-2"
}

variable "server_version" {
  description = "Couchbase Server version"
  type        = string
  default     = "8.0"
}

variable "availability_type" {
  description = "Availability zone type: 'single' or 'multi'"
  type        = string
  default     = "multi"
}

variable "support_plan" {
  description = "Support plan: 'basic', 'developer pro', or 'enterprise'"
  type        = string
  default     = "developer pro"
}

variable "support_timezone" {
  description = "Support timezone"
  type        = string
  default     = "ET"
}

variable "cpu" {
  description = "Number of vCPUs per node"
  type        = number
  default     = 8
}

variable "ram" {
  description = "RAM (GB) per node"
  type        = number
  default     = 32
}

variable "storage" {
  description = "Storage size (GB) per node"
  type        = number
  default     = 256
}

variable "disk_type" {
  description = "Disk type (e.g. gp3, io2)"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Disk IOPS per node. Defaults to the Capella recommended value for 256 GB gp3 (5740)."
  type        = number
  default     = 5740
}

variable "num_of_nodes" {
  description = "Number of nodes in the service group"
  type        = number
  default     = 3
}

variable "services" {
  description = "List of Couchbase services to enable"
  type        = list(string)
  default     = ["data", "query", "index", "search"]
}

variable "allowlist_cidr" {
  description = "CIDR to allowlist for cluster access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowlist_comment" {
  description = "Comment for the allowlist entry"
  type        = string
  default     = "Allow all access"
}

variable "db_username" {
  description = "Database credential username"
  type        = string
  default     = "developer"
}

variable "db_password" {
  description = "Database credential password. If null and db_password_secret is null, a password is auto-generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "db_password_secret" {
  description = "Name of the AWS Secrets Manager secret containing the database password (JSON key: \"key\"). Used when db_password is not set."
  type        = string
  default     = null
}
