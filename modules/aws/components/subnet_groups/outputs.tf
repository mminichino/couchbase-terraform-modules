#

output "subnet_ids" {
  description = "Subnet IDs included in the subnet groups"
  value       = local.subnet_ids
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.this.name
}

output "docdb_subnet_group_name" {
  value = aws_docdb_subnet_group.this.name
}

output "elasticache_subnet_group_name" {
  value = aws_elasticache_subnet_group.this.name
}

output "memorydb_subnet_group_name" {
  value = aws_memorydb_subnet_group.this.name
}

output "redshift_subnet_group_name" {
  value = aws_redshift_subnet_group.this.name
}

output "dax_subnet_group_name" {
  value = aws_dax_subnet_group.this.name
}

output "neptune_subnet_group_name" {
  value = aws_neptune_subnet_group.this.name
}
