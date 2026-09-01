#

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.81.0.0/16"
}

variable "public_key_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing the SSH public key (JSON key: \"key\")"
  type        = string
}

variable "private_key_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing the SSH private key (JSON key: \"key\")"
  type        = string
}

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
