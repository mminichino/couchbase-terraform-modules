# Deploy Cluster Nodes

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

resource "aws_security_group" "client_sg" {
  name        = "${var.id}-client-sg"
  description = "Client inbound traffic"
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
  vpc_security_group_ids      = [aws_security_group.client_sg.id]
  subnet_id                   = var.aws_subnet_id_list[each.value.global_index % length(var.aws_subnet_id_list)]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_iops
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/client.sh", {
    host_prep_version = var.host_prep_version
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
    Name = "client${each.value.group_index}${each.value.node_index + 1}-${var.id}"
  })
}
