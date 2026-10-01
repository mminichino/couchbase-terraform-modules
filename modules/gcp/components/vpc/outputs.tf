#

output "vpc_id" {
  description = "VPC network id"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.self_link
}

output "vpc_cidr" {
  description = "Subnet CIDR"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "subnet_id" {
  description = "Subnet id"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "Subnet self link"
  value       = google_compute_subnetwork.subnet.self_link
}

output "zones" {
  description = "Zones in the region, used to spread nodes"
  value       = local.zones
}

output "gcp_project_id" {
  description = "GCP project ID"
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "GCP region"
  value       = var.gcp_region
}
