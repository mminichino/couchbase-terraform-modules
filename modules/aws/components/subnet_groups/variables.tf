#

variable "id" {
  description = "Deployment ID used for subnet group names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID whose subnets are included in each subnet group"
  type        = string
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
