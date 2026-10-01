# Deploy Cluster Nodes

resource "random_string" "password" {
  count   = var.password == null && var.password_secret == null ? 1 : 0
  length  = 16
  special = false
}

data "google_secret_manager_secret_version" "password" {
  count   = var.password == null && var.password_secret != null ? 1 : 0
  secret  = var.password_secret
  project = var.gcp_project_id
}

locals {
  password = var.password != null ? var.password : (
    var.password_secret != null ? jsondecode(data.google_secret_manager_secret_version.password[0].secret_data)["password"] : random_string.password[0].result
  )
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

locals {
  node_groups_expanded = flatten([
    for group_index, spec in var.node_groups : [
      for node_index in range(spec.node_count) : {
        group_index  = group_index
        node_index   = node_index
        machine_type = spec.machine_type
        services     = spec.services
      }
    ]
  ])

  nodes = [
    for global_index, node in local.node_groups_expanded : merge(node, {
      key          = "${node.group_index}-${node.node_index}"
      global_index = global_index
      zone         = var.zones[global_index % length(var.zones)]
    })
  ]

  node_map = { for node in local.nodes : node.key => node }

  network_tag = "cb-${var.id}"
}

resource "google_compute_firewall" "couchbase" {
  name    = "cb-${var.id}"
  network = var.gcp_network
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "8091-8097", "9140", "11207", "11210", "11280", "18091-18097"]
  }

  allow {
    protocol = "udp"
    ports    = ["9123"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.network_tag]
}

resource "google_compute_firewall" "internal" {
  name    = "cb-${var.id}-internal"
  network = var.gcp_network
  project = var.gcp_project_id

  allow {
    protocol = "all"
  }

  source_ranges = [var.gcp_vpc_cidr]
  target_tags   = [local.network_tag]
}

resource "google_compute_disk" "data" {
  for_each = local.node_map
  name     = "data-${each.key}-${var.id}"
  type     = var.data_volume_type
  size     = var.data_volume_size
  zone     = each.value.zone
  project  = var.gcp_project_id

  labels = merge(var.labels, {
    name = "data-${each.key}-${var.id}"
  })
}

resource "google_compute_instance" "node_group" {
  for_each     = local.node_map
  name         = "node${each.value.group_index}${each.value.node_index + 1}-${var.id}"
  machine_type = each.value.machine_type
  zone         = each.value.zone
  project      = var.gcp_project_id

  tags = [local.network_tag]

  labels = merge(var.labels, {
    name = "node${each.value.group_index}${each.value.node_index + 1}-${var.id}"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.root_volume_size
      type  = var.root_volume_type
    }
  }

  attached_disk {
    source      = google_compute_disk.data[each.key].id
    device_name = "sdb"
  }

  network_interface {
    subnetwork = var.gcp_subnet
    access_config {}
  }

  metadata = {
    ssh-keys               = "ubuntu:${chomp(var.public_key)}"
    block-project-ssh-keys = "true"
    # cloud-init reads user-data so the provisioner can wait on cloud-init
    user-data = templatefile("${path.module}/scripts/server.sh", {
      version           = var.software_version
      host_prep_version = var.host_prep_version
      admin_user        = var.admin_user
      cbctl_version     = var.cbctl_version
    })
  }

  allow_stopping_for_update = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = self.network_interface[0].access_config[0].nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait > /dev/null 2>&1",
    ]
  }

  depends_on = [
    google_compute_firewall.couchbase,
    google_compute_firewall.internal,
  ]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

locals {
  primary_node_key        = length(local.nodes) > 0 ? local.nodes[0].key : null
  primary_node_private_ip = local.primary_node_key != null ? google_compute_instance.node_group[local.primary_node_key].network_interface[0].network_ip : null
  primary_node_public_ip  = local.primary_node_key != null ? google_compute_instance.node_group[local.primary_node_key].network_interface[0].access_config[0].nat_ip : null

  cluster_bootstrap = local.primary_node_key == null ? [] : concat(
    [
      "sudo /usr/local/bin/cbctl cluster create --name ${var.cluster_name} --password ${local.password} --ip-address ${local.primary_node_private_ip} --external-ip-address ${local.primary_node_public_ip} --services ${join(",", local.node_map[local.primary_node_key].services)} --server-group ${local.node_map[local.primary_node_key].zone} --data-path ${var.data_path} --no-ssl",
    ],
    [
      for node in local.nodes :
      "sudo /usr/local/bin/cbctl cluster join --password ${local.password} --rally-ip-address ${local.primary_node_private_ip} --ip-address ${google_compute_instance.node_group[node.key].network_interface[0].network_ip} --external-ip-address ${google_compute_instance.node_group[node.key].network_interface[0].access_config[0].nat_ip} --services ${join(",", node.services)} --server-group ${node.zone} --data-path ${var.data_path} --no-ssl"
      if node.global_index > 0
    ],
    [
      "sudo /usr/local/bin/cbctl cluster rebalance --password ${local.password} --rally-ip-address ${local.primary_node_private_ip} --no-ssl",
    ],
  )
}

resource "null_resource" "bootstrap_cluster" {
  count = local.primary_node_key != null ? 1 : 0

  depends_on = [google_compute_instance.node_group]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = local.primary_node_public_ip
  }

  provisioner "remote-exec" {
    inline = local.cluster_bootstrap
  }
}
