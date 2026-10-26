output "id" {
  value = module.multi_region.id
}

output "vpc_id" {
  value = module.multi_region.vpc_id
}

output "cluster_url" {
  value = module.multi_region.cluster_url
}

output "cluster_password" {
  sensitive = true
  value     = module.multi_region.cluster_password
}

output "arbiter" {
  value = module.multi_region.arbiter
}
