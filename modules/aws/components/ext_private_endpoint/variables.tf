#

variable "vpc_id" {
  description = "AWS VPC ID from modules/aws/components/vpc"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR of the VPC (used for endpoint security group ingress)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the interface VPC endpoint (typically module.vpc.subnet_id_list)"
  type        = list(string)
}

variable "service_name" {
  description = "VPC endpoint service name of the external cloud service"
  type        = string
}

variable "region" {
  description = "AWS region of the VPC (passed through to finalize_private_endpoint)"
  type        = string
}

variable "ports" {
  description = "TCP ports to allow from the VPC CIDR to the endpoint"
  type        = list(number)
  default     = [443]
}

variable "name" {
  description = "Name prefix for AWS resources"
  type        = string
  default     = "ext-private-endpoint"
}

variable "tags" {
  description = "Optional tags for AWS resources"
  type        = map(string)
  default     = {}
}
