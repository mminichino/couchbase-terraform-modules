#

output "organization_id" {
  description = "Organization ID"
  value       = couchbase-capella_cluster.this.organization_id
}

output "project_id" {
  description = "Project ID"
  value       = couchbase-capella_cluster.this.project_id
}

output "cluster_id" {
  description = "Capella cluster ID"
  value       = couchbase-capella_cluster.this.id
}

output "cluster_name" {
  description = "Capella cluster name"
  value       = couchbase-capella_cluster.this.name
}

output "connection_string" {
  description = "Capella cluster connection string"
  value       = couchbase-capella_cluster.this.connection_string
}

output "current_state" {
  description = "Current state of the Capella cluster"
  value       = couchbase-capella_cluster.this.current_state
}

output "allowlist_id" {
  description = "ID of the created allowlist entry"
  value       = couchbase-capella_allowlist.this.id
}

output "db_credential_id" {
  description = "ID of the database credential"
  value       = couchbase-capella_database_credential.this.id
}

output "db_username" {
  description = "Database credential username"
  value       = couchbase-capella_database_credential.this.name
}

output "db_password" {
  description = "Database credential password"
  value       = local.db_password
  sensitive   = true
}
