# Connect an application VPC (modules/aws/server) to Capella (modules/common/capella)
# using AWS PrivateLink.
#
# Flow (see https://docs.couchbase.com/cloud/security/add-aws-private-link.html):
# 1. Enable Capella private endpoint service
# 2. Create an interface VPC endpoint in the application VPC
# 3. Accept the endpoint in Capella
# 4. Enable private DNS on the VPC endpoint
# 5. Allow Capella ports on the endpoint security group
#
# DNS hostnames/resolution are already enabled by modules/aws/components/vpc.
# Default VPC network ACLs already allow the required traffic.

resource "couchbase-capella_private_endpoint_service" "this" {
  organization_id = var.organization_id
  project_id      = var.project_id
  cluster_id      = var.cluster_id
  enabled         = true
}

resource "aws_security_group" "endpoint" {
  name        = "${var.name}-sg"
  description = "Capella PrivateLink VPC endpoint"
  vpc_id      = var.vpc_id

  # Capella PrivateLink ports
  ingress {
    description = "Capella cluster ports"
    from_port   = 18091
    to_port     = 18203
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Capella data service ports"
    from_port   = 11207
    to_port     = 11308
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  dynamic "ingress" {
    for_each = var.enable_xdcr_ports ? [1] : []
    content {
      description = "Capella XDCR private endpoint ports"
      from_port   = 20091
      to_port     = 20117
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = couchbase-capella_private_endpoint_service.this.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = false

  # Private DNS is enabled after Capella accepts the endpoint (see null_resource below).
  lifecycle {
    ignore_changes = [private_dns_enabled]
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  depends_on = [couchbase-capella_private_endpoint_service.this]
}

resource "couchbase-capella_private_endpoints" "this" {
  organization_id = var.organization_id
  project_id      = var.project_id
  cluster_id      = var.cluster_id
  endpoint_id     = aws_vpc_endpoint.this.id
}

# Capella requires accepting the endpoint before private DNS can be enabled.
resource "null_resource" "enable_private_dns" {
  count = var.enable_private_dns ? 1 : 0

  triggers = {
    endpoint_id = aws_vpc_endpoint.this.id
    region      = var.region
  }

  provisioner "local-exec" {
    command = "aws ec2 modify-vpc-endpoint --vpc-endpoint-id ${aws_vpc_endpoint.this.id} --private-dns-enabled --region ${var.region}"
  }

  depends_on = [couchbase-capella_private_endpoints.this]
}
