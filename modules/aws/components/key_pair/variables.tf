#

variable "id" {
  type = string
}

variable "public_key" {
  type = string
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
