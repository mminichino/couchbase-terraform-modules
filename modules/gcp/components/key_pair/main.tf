#

data "google_secret_manager_secret_version" "public_key" {
  count   = var.public_key_secret_name != null ? 1 : 0
  secret  = var.public_key_secret_name
  project = var.gcp_project_id
}

data "google_secret_manager_secret_version" "private_key" {
  count   = var.private_key_secret_name != null ? 1 : 0
  secret  = var.private_key_secret_name
  project = var.gcp_project_id
}

locals {
  public_key_path  = var.public_key_file != null ? pathexpand("~/.ssh/${var.public_key_file}") : null
  private_key_path = var.private_key_file != null ? pathexpand("~/.ssh/${var.private_key_file}") : null

  public_key  = var.public_key_file != null ? trimspace(file(local.public_key_path)) : jsondecode(data.google_secret_manager_secret_version.public_key[0].secret_data)["key"]
  private_key = var.private_key_file != null ? file(local.private_key_path) : replace(jsondecode(data.google_secret_manager_secret_version.private_key[0].secret_data)["key"], "\\n", "\n")
}
