#

output "service_name" {
  description = "Capella AWS VPC endpoint service name"
  value       = couchbase-capella_private_endpoint_service.this.service_name
}

output "service_status" {
  description = "Capella private endpoint service status"
  value       = couchbase-capella_private_endpoint_service.this.status
}

output "vpc_endpoint_id" {
  description = "AWS VPC endpoint ID (vpce-...)"
  value       = aws_vpc_endpoint.this.id
}

output "vpc_endpoint_dns_entries" {
  description = "DNS entries for the AWS VPC endpoint"
  value       = aws_vpc_endpoint.this.dns_entry
}

output "security_group_id" {
  description = "Security group attached to the VPC endpoint"
  value       = aws_security_group.endpoint.id
}

output "endpoint_status" {
  description = "Capella private endpoint status (linked when complete)"
  value       = couchbase-capella_private_endpoints.this.status
}

output "private_endpoint_dns" {
  description = "Private endpoint DNS name from Capella"
  value       = couchbase-capella_private_endpoints.this.private_endpoint_dns
}
