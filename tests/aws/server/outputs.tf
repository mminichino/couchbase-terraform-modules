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
