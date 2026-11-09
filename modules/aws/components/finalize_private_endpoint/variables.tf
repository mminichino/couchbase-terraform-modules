#

variable "vpc_endpoint_id" {
  description = "AWS VPC endpoint ID from modules/aws/components/ext_private_endpoint"
  type        = string
}

variable "region" {
  description = "AWS region from modules/aws/components/ext_private_endpoint"
  type        = string
}
