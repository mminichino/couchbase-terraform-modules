#

output "nodes" {
  description = "Ordered list of deployed nodes (group 0 node 0 first)"
  value = [
    for node in local.nodes : {
      private_ip        = aws_instance.node_group[node.key].private_ip
      public_ip         = aws_instance.node_group[node.key].public_ip
      availability_zone = aws_instance.node_group[node.key].availability_zone
    }
  ]
}
