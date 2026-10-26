# Multi-region Couchbase cluster: a server group in each of two regions, plus an arbiter in a third.

provider "google" {
  project = var.gcp_project_id
  region  = var.regions[0]
}

module "id" {
  source = "../components/id"
}

module "key_pair" {
  source                  = "../components/key_pair"
  gcp_project_id          = var.gcp_project_id
  private_key_secret_name = var.private_key_secret_name
  public_key_secret_name  = var.public_key_secret_name
  public_key_file         = var.public_key_file
  private_key_file        = var.private_key_file
}

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

  network_tag = "cb-${module.id.id}"

  all_regions = distinct(concat(var.regions, [var.arbiter_region]))

  subnet_cidrs = merge(
    { for idx, region in var.regions : region => var.subnet_cidrs[idx] },
    { (var.arbiter_region) = var.arbiter_subnet_cidr },
  )
}

resource "google_compute_network" "vpc" {
  name                    = "vpc-${module.id.id}"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
  description             = "Couchbase VPC ${module.id.id}"

  lifecycle {
    precondition {
      condition     = !contains(var.regions, var.arbiter_region)
      error_message = "arbiter_region must be a different region from the two service regions."
    }

    precondition {
      condition     = length(distinct(concat(var.subnet_cidrs, [var.arbiter_subnet_cidr]))) == 3
      error_message = "subnet_cidrs and arbiter_subnet_cidr must be three distinct CIDR blocks."
    }

    precondition {
      condition = alltrue([
        for region in var.regions : length(local.available_zones[region]) >= 3
      ])
      error_message = "Each service region must have at least three zones after applying skip_zone."
    }

    precondition {
      condition     = length(local.available_zones[var.arbiter_region]) >= 1
      error_message = "Arbiter region ${var.arbiter_region} has no available zones after applying skip_zone."
    }
  }
}

resource "google_compute_subnetwork" "regional" {
  for_each = local.subnet_cidrs

  name          = "subnet-${each.key}-${module.id.id}"
  ip_cidr_range = each.value
  region        = each.key
  network       = google_compute_network.vpc.id
  project       = var.gcp_project_id
}

data "google_compute_zones" "available" {
  for_each = toset(local.all_regions)

  project = var.gcp_project_id
  region  = each.value
  status  = "UP"
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

locals {
  available_zones = {
    for region in local.all_regions :
    region => sort([
      for zone in data.google_compute_zones.available[region].names : zone
      if !contains(var.skip_zone, zone)
    ])
  }

  # First three usable zones keep expansions of three nodes balanced, one per zone.
  zones_by_region = {
    for region in local.all_regions :
    region => slice(
      local.available_zones[region],
      0,
      min(3, length(local.available_zones[region]))
    )
  }

  service_nodes = flatten([
    for region_index, region in var.regions : [
      for node_index in range(var.nodes_per_region) : {
        key          = "${region_index}-${node_index}"
        name         = "node${region_index}${node_index + 1}-${module.id.id}"
        region       = region
        region_index = region_index
        node_index   = node_index
        zone = local.zones_by_region[region][
          node_index % length(local.zones_by_region[region])
        ]
        server_group     = region
        services         = var.services
        arbiter          = false
        machine_type     = var.machine_type
        root_volume_type = var.root_volume_type
        data_volume_type = var.data_volume_type
      }
    ]
  ])

  arbiter_node = {
    key              = "arbiter"
    name             = "arbiter-${module.id.id}"
    region           = var.arbiter_region
    region_index     = length(var.regions)
    node_index       = 0
    zone             = local.zones_by_region[var.arbiter_region][0]
    server_group     = var.arbiter_region
    services         = slice(var.services, 0, 0)
    arbiter          = true
    machine_type     = var.arbiter_machine_type
    root_volume_type = var.arbiter_root_volume_type
    data_volume_type = var.arbiter_data_volume_type
  }

  nodes    = concat(local.service_nodes, [local.arbiter_node])
  node_map = { for node in local.nodes : node.key => node }
}

resource "google_compute_firewall" "couchbase" {
  name    = "cb-${module.id.id}"
  network = google_compute_network.vpc.id
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
  name    = "cb-${module.id.id}-internal"
  network = google_compute_network.vpc.id
  project = var.gcp_project_id

  allow {
    protocol = "all"
  }

  source_ranges = values(local.subnet_cidrs)
  target_tags   = [local.network_tag]
}

resource "google_compute_disk" "data" {
  for_each = local.node_map

  name    = "data-${each.key}-${module.id.id}"
  type    = each.value.data_volume_type
  size    = each.value.arbiter ? var.arbiter_data_volume_size : var.data_volume_size
  zone    = each.value.zone
  project = var.gcp_project_id

  labels = merge(var.labels, {
    name = "data-${each.key}-${module.id.id}"
  })
}

resource "google_compute_instance" "node" {
  for_each = local.node_map

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone
  project      = var.gcp_project_id

  tags = [local.network_tag]

  labels = merge(var.labels, {
    name = each.value.name
  })

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.root_volume_size
      type  = each.value.root_volume_type
    }
  }

  attached_disk {
    source      = google_compute_disk.data[each.key].id
    device_name = "sdb"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.regional[each.value.region].self_link
    access_config {}
  }

  metadata = {
    ssh-keys               = "ubuntu:${chomp(module.key_pair.public_key)}"
    block-project-ssh-keys = "true"
    # cloud-init reads user-data so the provisioner can wait on cloud-init
    user-data = templatefile("${path.module}/../components/cluster/scripts/server.sh", {
      version           = var.software_version
      host_prep_version = var.host_prep_version
      admin_user        = "ubuntu"
      cbctl_version     = var.cbctl_version
    })
  }

  allow_stopping_for_update = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = module.key_pair.private_key
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
  primary_key        = local.service_nodes[0].key
  primary_private_ip = google_compute_instance.node[local.primary_key].network_interface[0].network_ip
  primary_public_ip  = google_compute_instance.node[local.primary_key].network_interface[0].access_config[0].nat_ip

  cluster_bootstrap = concat(
    [
      "sudo /usr/local/bin/cbctl cluster create --name ${var.cluster_name} --password ${local.password} --ip-address ${local.primary_private_ip} --external-ip-address ${local.primary_public_ip} --services ${join(",", local.service_nodes[0].services)} --server-group ${local.service_nodes[0].server_group} --data-path ${var.data_path} --no-ssl",
    ],
    [
      for node in local.service_nodes :
      "sudo /usr/local/bin/cbctl cluster join --password ${local.password} --rally-ip-address ${local.primary_private_ip} --ip-address ${google_compute_instance.node[node.key].network_interface[0].network_ip} --external-ip-address ${google_compute_instance.node[node.key].network_interface[0].access_config[0].nat_ip} --services ${join(",", node.services)} --server-group ${node.server_group} --data-path ${var.data_path} --no-ssl"
      if node.key != local.primary_key
    ],
    [
      "sudo /usr/local/bin/cbctl cluster join --password ${local.password} --rally-ip-address ${local.primary_private_ip} --ip-address ${google_compute_instance.node[local.arbiter_node.key].network_interface[0].network_ip} --external-ip-address ${google_compute_instance.node[local.arbiter_node.key].network_interface[0].access_config[0].nat_ip} --arbiter --server-group ${local.arbiter_node.server_group} --no-ssl",
    ],
    [
      "sudo /usr/local/bin/cbctl cluster rebalance --password ${local.password} --rally-ip-address ${local.primary_private_ip} --no-ssl",
    ],
  )
}

resource "null_resource" "bootstrap_cluster" {
  depends_on = [google_compute_instance.node]

  triggers = {
    nodes = jsonencode([
      for node in local.nodes : {
        key          = node.key
        id           = google_compute_instance.node[node.key].id
        services     = node.services
        server_group = node.server_group
        arbiter      = node.arbiter
        machine_type = node.machine_type
      }
    ])
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = module.key_pair.private_key
    host        = local.primary_public_ip
  }

  provisioner "remote-exec" {
    inline = local.cluster_bootstrap
  }
}
