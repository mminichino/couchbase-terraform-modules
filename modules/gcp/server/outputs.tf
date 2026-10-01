#

output "id" {
  value = module.id.id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_name" {
  value = module.vpc.vpc_name
}

output "subnet_id" {
  value = module.vpc.subnet_id
}

output "subnet_self_link" {
  value = module.vpc.subnet_self_link
}

output "zones" {
  description = "Zones in the region, used to spread nodes"
  value       = module.vpc.zones
}

output "security_group" {
  value = module.nodes.security_group
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "public_key" {
  value = module.key_pair.public_key
}

output "private_key" {
  value     = local.private_key
  sensitive = true
}

output "nodes" {
  description = "Ordered list of deployed nodes (group 0 node 0 first)"
  value       = module.nodes.nodes
}

output "primary_node" {
  description = "The first node (group 0, node 0)"
  value       = length(module.nodes.nodes) > 0 ? module.nodes.nodes[0] : null
}

output "cluster_url" {
  description = "Cluster admin URL"
  value       = module.nodes.cluster_admin_url
}

output "cluster_password" {
  description = "Cluster admin password"
  sensitive   = true
  value       = module.nodes.cluster_password
}
