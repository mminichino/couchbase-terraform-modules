#

output "network_peer_id" {
  description = "Capella network peer ID"
  value       = couchbase-capella_network_peer.this.id
}

output "peering_connection_id" {
  description = "AWS VPC peering connection ID (pcx-...)"
  value       = aws_vpc_peering_connection_accepter.this.id
}

output "capella_cidr" {
  description = "Capella cluster VPC CIDR routed through the peering connection"
  value       = local.capella_cidr
}

output "hosted_zone_id" {
  description = "Capella private hosted zone ID associated with the application VPC"
  value       = local.hosted_zone_id
}

output "route_table_ids" {
  description = "Route table IDs updated with a route to Capella"
  value       = local.route_table_ids
}

output "status" {
  description = "Capella network peer status"
  value       = couchbase-capella_network_peer.this.status
}

output "commands" {
  description = "Follow-up AWS CLI commands returned by Capella (executed via Terraform resources)"
  value       = couchbase-capella_network_peer.this.commands
}
