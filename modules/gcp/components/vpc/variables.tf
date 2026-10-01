#

variable "id" {
  description = "Deployment ID"
  type        = string
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the subnet."
  type        = string
}

variable "cidr_block" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.55.0.0/16"
}
