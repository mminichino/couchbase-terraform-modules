#

variable "vpc_id" {
  description = "VPC ID from modules/aws/components/vpc"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR (authorization target and DNS server derivation)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs to associate with the Client VPN endpoint (typically module.vpc.subnet_id_list)"
  type        = list(string)
}

variable "name" {
  description = "Name prefix for Client VPN resources"
  type        = string
  default     = "client-vpn"
}

variable "client_cidr_block" {
  description = "CIDR assigned to VPN clients. Must not overlap the VPC CIDR (/22 to /12)."
  type        = string
  default     = "10.250.0.0/16"
}

variable "split_tunnel" {
  description = "Enable split tunnel so only VPC-bound traffic uses the VPN"
  type        = bool
  default     = true
}

variable "dns_servers" {
  description = "DNS servers pushed to VPN clients. Defaults to the VPC AmazonProvidedDNS (.2 address)."
  type        = list(string)
  default     = null
}

variable "session_timeout_hours" {
  description = "Maximum VPN session duration in hours (8, 10, 12, 24)"
  type        = number
  default     = 24
}

variable "transport_protocol" {
  description = "Transport protocol for Client VPN (udp or tcp)"
  type        = string
  default     = "udp"
}

variable "vpn_port" {
  description = "VPN port (443 or 1194)"
  type        = number
  default     = 443
}

variable "authorize_vpc" {
  description = "Create an authorization rule granting VPN clients access to the VPC CIDR"
  type        = bool
  default     = true
}

variable "additional_authorized_cidrs" {
  description = "Extra CIDRs to authorize for VPN clients (e.g. Capella CIDR via peering/PrivateLink)"
  type        = list(string)
  default     = []
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention for Client VPN connection logs"
  type        = number
  default     = 30
}

variable "certificate_common_name" {
  description = "Common name for the generated CA-signed server certificate"
  type        = string
  default     = "client-vpn.internal"
}

variable "client_certificate_common_name" {
  description = "Common name for the generated client certificate"
  type        = string
  default     = "client.client-vpn.internal"
}

variable "ovpn_output_path" {
  description = "If set, write the mutual-auth .ovpn profile (with embedded client cert/key) to this path"
  type        = string
  default     = null
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
