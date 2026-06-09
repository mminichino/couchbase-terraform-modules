# Deploy Node Group

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

# data "aws_route53_zone" "public_zone" {
#   name = var.parent_domain
# }

data "aws_key_pair" "ssh_key" {
  key_name = var.aws_key_pair
}

data "aws_ec2_instance_type" "machine_type" {
  instance_type = var.machine_type
}

resource "aws_security_group" "couchbase_sg" {
  name        = "${var.id}-couchbase-sg"
  description = "Couchbase inbound traffic"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.aws_vpc_cidr]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 8091
    to_port          = 8097
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 9123
    to_port          = 9123
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 9140
    to_port          = 9140
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 11210
    to_port          = 11210
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 11280
    to_port          = 11280
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 11207
    to_port          = 11207
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 18091
    to_port          = 18097
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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

# locals {
#   cluster_domain = "${var.id}.${data.aws_route53_zone.public_zone.name}"
#   cpu_count      = data.aws_ec2_instance_type.machine_type.default_vcpus
# }

resource "aws_instance" "node_group" {
  count                       = var.node_count
  ami                         = data.aws_ami.ubuntu_linux.id
  instance_type               = var.machine_type
  key_name                    = data.aws_key_pair.ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.couchbase_sg.id]
  subnet_id                   = var.aws_subnet_id_list[count.index % length(var.aws_subnet_id_list)]
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
    version = var.software_version
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
    Name = "node${var.node_group}${count.index + 1}-${var.id}"
  })
}

# resource "aws_route53_record" "host_records" {
#   count   = var.node_count
#   zone_id = data.aws_route53_zone.public_zone.zone_id
#   name    = "node${var.node_group}${count.index + 1}"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.node_group[count.index].public_ip]
#   depends_on = [aws_instance.node_group]
# }

locals {
  primary_node_private_ip = var.node_count > 0 ? aws_instance.node_group[0].private_ip : null
  primary_node_public_ip  = var.node_count > 0 ? aws_instance.node_group[0].public_ip : null
  # instance_hostnames      = [for fqdn in aws_route53_record.host_records[*].fqdn : trimsuffix(fqdn, ".")]
}
