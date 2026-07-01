# Couchbase Enterprise Server Outputs

output "id" {
  value = module.server.id
}

output "vpc_id" {
  value = module.server.vpc_id
}

output "cluster_url" {
  value = module.server.cluster_url
}

output "cluster_password" {
  sensitive = true
  value     = module.server.cluster_password
}

output "server_ip_list" {
  value = [for node in module.server.nodes : node.public_ip]
}

output "client_ip_list" {
  value = [for node in module.client.nodes : node.public_ip]
}
