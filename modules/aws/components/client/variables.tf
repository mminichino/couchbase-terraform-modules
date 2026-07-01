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
  description = "The root volume size"
  default     = 64
  type        = number
}

variable "root_volume_type" {
  description = "The root volume type"
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "The root volume IOPS"
  default     = 3000
  type        = number
}

variable "private_key" {
  description = "Private key"
  type        = string
}

variable "host_prep_version" {
  type    = string
  default = "2.0.0a1"
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
