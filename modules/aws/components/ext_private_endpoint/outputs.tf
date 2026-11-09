#

output "vpc_endpoint_id" {
  description = "AWS VPC endpoint ID (vpce-...). Pass to finalize_private_endpoint."
  value       = aws_vpc_endpoint.this.id
}

output "region" {
  description = "AWS region of the VPC endpoint. Pass to finalize_private_endpoint."
  value       = var.region
}

output "vpc_endpoint_dns_entries" {
  description = "DNS entries for the AWS VPC endpoint"
  value       = aws_vpc_endpoint.this.dns_entry
}

output "security_group_id" {
  description = "Security group attached to the VPC endpoint"
  value       = aws_security_group.endpoint.id
}

output "service_name" {
  description = "VPC endpoint service name used for this endpoint"
  value       = aws_vpc_endpoint.this.service_name
}
