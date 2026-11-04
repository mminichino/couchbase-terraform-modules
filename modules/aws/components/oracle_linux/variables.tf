#

variable "id" {
  description = "Deployment ID"
  type        = string
}

variable "aws_vpc_id" {
  description = "AWS VPC id"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "aws_key_pair" {
  type = string
}

variable "aws_subnet_id_list" {
  description = "Subnet id list"
  type        = list(string)
}

variable "node_groups" {
  description = "Node group specifications"
  type = list(object({
    node_count   = number
    machine_type = string
  }))
}

variable "root_volume_size" {
  description = "The root volume size in GB"
  default     = 64
  type        = number
}

variable "root_volume_type" {
  description = "The root volume type"
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "Root volume IOPS. When null, uses Couchbase Capella AWS gp3 defaults for root_volume_size."
  default     = null
  type        = number
}

variable "data_volume_iops" {
  description = "Data volume IOPS. When null, uses Couchbase Capella AWS gp3 defaults for data_volume_size."
  default     = null
  type        = number
}

variable "data_volume_throughput" {
  description = "The data volume throughput"
  default     = 600
  type        = number
}

variable "data_volume_size" {
  description = "The data volume size in GB"
  default     = 256
  type        = number
}

variable "private_key" {
  description = "SSH private key content. Used when private_key_file and private_key_secret are not set."
  type        = string
  default     = null
  sensitive   = true
}

variable "private_key_secret" {
  description = "Name of the AWS Secrets Manager secret containing the SSH private key (JSON key: \"key\")"
  type        = string
  default     = null
}

variable "private_key_file" {
  description = "SSH private key filename in ~/.ssh (e.g. id_rsa). Used instead of private_key_secret when set."
  type        = string
  default     = null
}

variable "host_prep_version" {
  type    = string
  default = "2.0.0"
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
