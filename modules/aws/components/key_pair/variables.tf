#

variable "id" {
  type = string
}

variable "public_key_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing the SSH public key (JSON key: \"key\")"
  type        = string
}

variable "private_key_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing the SSH private key (JSON key: \"key\")"
  type        = string
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
