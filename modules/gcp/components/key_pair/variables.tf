#

variable "gcp_project_id" {
  description = "GCP project ID. Required when SSH keys are read from Secret Manager."
  type        = string
  default     = null
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
