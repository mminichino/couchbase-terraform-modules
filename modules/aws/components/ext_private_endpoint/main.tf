# Phase 1: create the AWS-side interface VPC endpoint for an external cloud service.
# Private DNS stays disabled until the endpoint is registered with the external
# service; then call modules/aws/components/finalize_private_endpoint.

resource "aws_security_group" "endpoint" {
  name        = "${var.name}-sg"
  description = "External PrivateLink VPC endpoint"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ports
    content {
      description = "Port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
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
  service_name        = var.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = false

  # Private DNS is enabled by finalize_private_endpoint after external registration.
  lifecycle {
    ignore_changes = [private_dns_enabled]
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
