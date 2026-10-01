#

output "nodes" {
  description = "Ordered list of deployed nodes (group 0 node 0 first)"
  value = [
    for node in local.nodes : {
      private_ip = google_compute_instance.node_group[node.key].network_interface[0].network_ip
      public_ip  = google_compute_instance.node_group[node.key].network_interface[0].access_config[0].nat_ip
      zone       = node.zone
      services   = node.services
    }
  ]
}

output "primary_node_private_ip" {
  description = "Private IP of the first node (group 0, node 0)"
  value       = local.primary_node_private_ip
}

output "primary_node_public_ip" {
  description = "Public IP of the first node (group 0, node 0)"
  value       = local.primary_node_public_ip
}

output "cluster_admin_url" {
  description = "Cluster admin URL"
  value       = "https://${local.primary_node_public_ip}:18091"
}

output "cluster_password" {
  description = "Cluster admin password"
  sensitive   = true
  value       = local.password
}

output "security_group" {
  value = google_compute_firewall.couchbase.id
}
