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

output "server_certificate_arn" {
  description = "ACM server certificate ARN used by the endpoint"
  value       = aws_acm_certificate.server.arn
}

output "security_group_id" {
  description = "Security group attached to the Client VPN endpoint"
  value       = aws_security_group.vpn.id
}

output "network_association_ids" {
  description = "Client VPN network association IDs"
  value       = aws_ec2_client_vpn_network_association.this[*].id
}

output "ovpn_config" {
  description = "Mutual-auth Client VPN profile with embedded client certificate and key"
  value       = local.ovpn
  sensitive   = true
}

output "client_certificate_pem" {
  description = "Client certificate PEM"
  value       = tls_locally_signed_cert.client.cert_pem
  sensitive   = true
}

output "client_private_key_pem" {
  description = "Client private key PEM"
  value       = tls_private_key.client.private_key_pem
  sensitive   = true
}

output "ovpn_file_path" {
  description = "Path to the written .ovpn file when ovpn_output_path is set"
  value       = try(local_sensitive_file.ovpn[0].filename, null)
}
