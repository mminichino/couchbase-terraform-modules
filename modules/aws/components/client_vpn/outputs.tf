#

output "client_vpn_endpoint_id" {
  description = "Client VPN endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "client_vpn_endpoint_arn" {
  description = "Client VPN endpoint ARN"
  value       = aws_ec2_client_vpn_endpoint.this.arn
}

output "dns_name" {
  description = "DNS name clients use to connect"
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
}

output "self_service_portal_url" {
  description = "Self-service portal URL (when enabled)"
  value       = aws_ec2_client_vpn_endpoint.this.self_service_portal_url
}

output "saml_provider_arn" {
  description = "IAM SAML provider ARN used for federated authentication"
  value       = local.saml_provider_arn
}

output "server_certificate_arn" {
  description = "ACM server certificate ARN used by the endpoint"
  value       = local.server_certificate_arn
}

output "security_group_id" {
  description = "Security group attached to the Client VPN endpoint"
  value       = aws_security_group.vpn.id
}

output "network_association_ids" {
  description = "Client VPN network association IDs"
  value       = aws_ec2_client_vpn_network_association.this[*].id
}
