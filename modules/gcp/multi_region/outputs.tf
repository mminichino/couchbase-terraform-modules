output "id" {
  value = module.id.id
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "vpc_self_link" {
  value = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Subnet self links keyed by region"
  value = {
    for region, subnet in google_compute_subnetwork.regional : region => subnet.self_link
  }
}

output "subnet_cidrs" {
  description = "Subnet CIDRs keyed by region"
  value       = local.subnet_cidrs
}

output "zones" {
  description = "Zones used to place nodes, keyed by region. Service regions use the first three zones that are not in skip_zone."
  value       = local.zones_by_region
}

output "security_group" {
  value = google_compute_firewall.couchbase.id
}

output "public_key" {
  value = module.key_pair.public_key
}

output "private_key" {
  value     = module.key_pair.private_key
  sensitive = true
}

output "nodes" {
  description = "Service nodes, region 0 node 0 first. The arbiter is a separate output."
  value = [
    for node in local.service_nodes : {
      private_ip   = google_compute_instance.node[node.key].network_interface[0].network_ip
      public_ip    = google_compute_instance.node[node.key].network_interface[0].access_config[0].nat_ip
      zone         = node.zone
      region       = node.region
      server_group = node.server_group
      services     = node.services
    }
  ]
}

output "primary_node" {
  description = "The first service node (first region, node 0)"
  value = length(local.service_nodes) > 0 ? {
    private_ip   = google_compute_instance.node[local.service_nodes[0].key].network_interface[0].network_ip
    public_ip    = google_compute_instance.node[local.service_nodes[0].key].network_interface[0].access_config[0].nat_ip
    zone         = local.service_nodes[0].zone
    region       = local.service_nodes[0].region
    server_group = local.service_nodes[0].server_group
    services     = local.service_nodes[0].services
  } : null
}

output "arbiter" {
  description = "Arbiter node in the third region"
  value = {
    private_ip   = google_compute_instance.node[local.arbiter_node.key].network_interface[0].network_ip
    public_ip    = google_compute_instance.node[local.arbiter_node.key].network_interface[0].access_config[0].nat_ip
    zone         = local.arbiter_node.zone
    region       = local.arbiter_node.region
    server_group = local.arbiter_node.server_group
  }
}

output "cluster_url" {
  description = "Cluster admin URL"
  value       = "https://${google_compute_instance.node[local.service_nodes[0].key].network_interface[0].access_config[0].nat_ip}:18091"
}

output "cluster_password" {
  description = "Cluster admin password"
  sensitive   = true
  value       = local.password
}
