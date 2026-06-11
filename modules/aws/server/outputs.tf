#

output "id" {
  value = module.id.id
}

output "vpc_id" {
  value = module.vpc.vpc_id
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
