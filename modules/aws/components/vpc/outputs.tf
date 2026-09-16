#

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "subnet_id_list" {
  value = aws_subnet.subnets[*].id
}

output "route_table_id" {
  description = "Primary public route table ID"
  value       = aws_route_table.default.id
}
