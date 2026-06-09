#

variable "id" {
  description = "Deployment ID"
}

variable "cidr_block" {
  description = "VPC CIDR"
  default = "10.55.0.0/16"
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_name" {
  description = "Override EKS cluster name for subnet discovery tags"
  type        = string
  default     = null
}
