# Deploy Client Nodes

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

  network_tag = "client-${var.id}"
}

resource "google_compute_firewall" "client" {
  name    = "client-${var.id}"
  network = var.gcp_network
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.network_tag]
}

resource "google_compute_firewall" "internal" {
  name    = "client-${var.id}-internal"
  network = var.gcp_network
  project = var.gcp_project_id

  allow {
    protocol = "all"
  }

  source_ranges = [var.gcp_vpc_cidr]
  target_tags   = [local.network_tag]
}

resource "google_compute_instance" "node_group" {
  for_each     = local.node_map
  name         = "client${each.value.group_index}${each.value.node_index + 1}-${var.id}"
  machine_type = each.value.machine_type
  zone         = each.value.zone
  project      = var.gcp_project_id

  tags = [local.network_tag]

  labels = merge(var.labels, {
    name = "client${each.value.group_index}${each.value.node_index + 1}-${var.id}"
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.root_volume_size
      type  = var.root_volume_type
    }
  }

  network_interface {
    subnetwork = var.gcp_subnet
    access_config {}
  }

  metadata = {
    ssh-keys               = "ubuntu:${chomp(var.public_key)}"
    block-project-ssh-keys = "true"
    # cloud-init reads user-data so the provisioner can wait on cloud-init
    user-data = templatefile("${path.module}/scripts/client.sh", {
      host_prep_version = var.host_prep_version
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
    google_compute_firewall.client,
    google_compute_firewall.internal,
  ]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}
