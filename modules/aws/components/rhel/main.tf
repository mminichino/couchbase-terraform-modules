# Deploy RHEL 8 Nodes

data "aws_secretsmanager_secret_version" "private_key" {
  count     = var.private_key == null && var.private_key_file == null && var.private_key_secret != null ? 1 : 0
  secret_id = var.private_key_secret
}

locals {
  private_key_path = var.private_key_file != null ? pathexpand("~/.ssh/${var.private_key_file}") : null
  private_key = var.private_key != null ? var.private_key : (
    var.private_key_file != null ? file(local.private_key_path) : replace(jsondecode(data.aws_secretsmanager_secret_version.private_key[0].secret_string)["key"], "\\n", "\n")
  )
}

data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat's AWS account ID

  filter {
    name   = "name"
    values = ["RHEL-8.*_HVM-*-x86_64-*-Hourly2-GP3"]
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
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_key_pair" "ssh_key" {
  key_name = var.aws_key_pair
}

resource "aws_security_group" "rhel_sg" {
  name        = "${var.id}-rhel-sg"
  description = "RHEL inbound traffic"
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

  # Oracle
  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Postgres
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MySQL
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MongoDB
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis
  ingress {
    from_port   = 6379
    to_port     = 6379
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
    Name = "${var.id}-rhel-sg"
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

  # Capella AWS gp3/io2 default IOPS by storage size:
  # https://docs.couchbase.com/cloud/clusters/scale-database.html#IOPS-Defaults
  root_volume_iops = var.root_volume_iops != null ? var.root_volume_iops : (
    var.root_volume_size >= 1000 ? 16000 : 3000 + floor(var.root_volume_size / 100) * 1370
  )
  data_volume_iops = var.data_volume_iops != null ? var.data_volume_iops : (
    var.data_volume_size >= 1000 ? 16000 : 3000 + floor(var.data_volume_size / 100) * 1370
  )
}

resource "aws_instance" "node_group" {
  for_each                    = local.node_map
  ami                         = data.aws_ami.rhel.id
  instance_type               = each.value.machine_type
  key_name                    = data.aws_key_pair.ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.rhel_sg.id]
  subnet_id                   = var.aws_subnet_id_list[each.value.global_index % length(var.aws_subnet_id_list)]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = local.root_volume_iops
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = var.data_volume_size
    iops        = local.data_volume_iops
    throughput  = var.data_volume_throughput
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/rhel.sh", {
    host_prep_version = var.host_prep_version
  }))

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = local.private_key
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait > /dev/null 2>&1",
    ]
  }

  tags = merge(var.tags, {
    Name = "rhel${each.value.group_index}${each.value.node_index + 1}-${var.id}"
  })
}
