#

output "nodes" {
  description = "Ordered list of deployed nodes (group 0 node 0 first)"
  value = [
    for node in local.nodes : {
      private_ip = google_compute_instance.node_group[node.key].network_interface[0].network_ip
      public_ip  = google_compute_instance.node_group[node.key].network_interface[0].access_config[0].nat_ip
      zone       = node.zone
    }
  ]
}
