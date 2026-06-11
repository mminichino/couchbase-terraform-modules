# Deploy Cluster Nodes

resource "random_string" "password" {
  length  = 16
  special = false
}

locals {
  password = coalesce(var.password, random_string.password.result)
}

data "aws_ami" "ubuntu_linux" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_key_pair" "ssh_key" {
  key_name = var.aws_key_pair
}

resource "aws_security_group" "couchbase_sg" {
  name        = "${var.id}-couchbase-sg"
  description = "Couchbase inbound traffic"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8091
    to_port     = 8097
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9123
    to_port     = 9123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9140
    to_port     = 9140
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 11210
    to_port     = 11210
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 11280
    to_port     = 11280
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 11207
    to_port     = 11207
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 18091
    to_port     = 18097
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.id}-couchbase-sg"
  })
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
    })
  ]

  node_map = { for node in local.nodes : node.key => node }
}

resource "aws_instance" "node_group" {
  for_each                    = local.node_map
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = each.value.machine_type
  key_name                    = data.aws_key_pair.ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.couchbase_sg.id]
  subnet_id                   = var.aws_subnet_id_list[each.value.global_index % length(var.aws_subnet_id_list)]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_iops
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = var.data_volume_size
    iops        = var.data_volume_iops
    throughput  = var.data_volume_throughput
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/server.sh", {
    version           = var.software_version
    host_prep_version = var.host_prep_version
    admin_user        = var.admin_user
  }))

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait > /dev/null 2>&1",
    ]
  }

  tags = merge(var.tags, {
    Name = "node${each.value.group_index}${each.value.node_index + 1}-${var.id}"
  })
}

locals {
  primary_node_key = length(local.nodes) > 0 ? local.nodes[0].key : null
  primary_node_private_ip = local.primary_node_key != null ? aws_instance.node_group[local.primary_node_key].private_ip : null
  primary_node_public_ip = local.primary_node_key != null ? aws_instance.node_group[local.primary_node_key].public_ip : null
}

resource "null_resource" "create_cluster" {
  count = local.primary_node_key != null ? 1 : 0

  depends_on = [aws_instance.node_group]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = aws_instance.node_group[local.primary_node_key].public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /root/.local/bin/swmgr cluster --name ${var.cluster_name} --password ${local.password} --ip-address ${aws_instance.node_group[local.primary_node_key].private_ip} --external-ip-address ${aws_instance.node_group[local.primary_node_key].public_ip} --services ${join(",", local.node_map[local.primary_node_key].services)} --server-group ${aws_instance.node_group[local.primary_node_key].availability_zone} --data-path ${var.data_path} create",
    ]
  }
}

resource "null_resource" "join_cluster" {
  for_each = {
    for node in local.nodes : node.key => node
    if node.global_index > 0
  }

  depends_on = [null_resource.create_cluster, aws_instance.node_group]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = aws_instance.node_group[each.key].public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /root/.local/bin/swmgr cluster --password ${local.password} --rally-ip-address ${aws_instance.node_group[local.primary_node_key].private_ip} --ip-address ${aws_instance.node_group[each.key].private_ip} --external-ip-address ${aws_instance.node_group[each.key].public_ip} --services ${join(",", each.value.services)} --server-group ${aws_instance.node_group[each.key].availability_zone} --data-path ${var.data_path} add",
    ]
  }
}

resource "null_resource" "rebalance" {
  count = local.primary_node_key != null ? 1 : 0

  depends_on = [null_resource.create_cluster, null_resource.join_cluster]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = aws_instance.node_group[local.primary_node_key].public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /root/.local/bin/swmgr cluster --password ${local.password} --rally-ip-address ${aws_instance.node_group[local.primary_node_key].private_ip} rebalance",
    ]
  }
}
