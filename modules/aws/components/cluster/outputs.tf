#

output "nodes" {
  description = "Ordered list of deployed nodes (group 0 node 0 first)"
  value = [
    for node in local.nodes : {
      private_ip        = aws_instance.node_group[node.key].private_ip
      public_ip         = aws_instance.node_group[node.key].public_ip
      availability_zone = aws_instance.node_group[node.key].availability_zone
      services          = node.services
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
