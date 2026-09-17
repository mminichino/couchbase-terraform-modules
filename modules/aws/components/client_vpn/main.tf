# Client VPN endpoint for a VPC from modules/aws/components/vpc.
# Uses mutual (certificate) authentication and emits a ready-to-import .ovpn profile.

locals {
  dns_servers = var.dns_servers != null ? var.dns_servers : [cidrhost(var.vpc_cidr, 2)]

  authorized_cidrs = concat(
    var.authorize_vpc ? [var.vpc_cidr] : [],
    var.additional_authorized_cidrs
  )

  # Endpoint dns_name may be reported as *.cvpn-endpoint-....; clients need the bare name.
  remote_host = replace(aws_ec2_client_vpn_endpoint.this.dns_name, "*.", "")

  # Built to match AWS Client VPN mutual-auth profile format (export API not in AWS provider 5.x).
  ovpn = <<-EOT
client
dev tun
proto ${var.transport_protocol}
remote ${local.remote_host} ${var.vpn_port}
remote-random-hostname
resolv-retry infinite
nobind
remote-cert-tls server
cipher AES-256-GCM
verb 3
<ca>
${tls_self_signed_cert.ca.cert_pem}</ca>
<cert>
${tls_locally_signed_cert.client.cert_pem}</cert>
<key>
${tls_private_key.client.private_key_pem}</key>
reneg-sec 0
EOT
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name = "${var.certificate_common_name} CA"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = var.certificate_common_name
  }

  dns_names = [var.certificate_common_name]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "server" {
  private_key       = tls_private_key.server.private_key_pem
  certificate_body  = tls_locally_signed_cert.server.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem

  tags = merge(var.tags, {
    Name = "${var.name}-server-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name = var.client_certificate_common_name
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "aws_cloudwatch_log_group" "vpn" {
  name_prefix       = "/aws/client-vpn/${var.name}-"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name}-logs"
  })
}

resource "aws_cloudwatch_log_stream" "vpn" {
  name           = var.name
  log_group_name = aws_cloudwatch_log_group.vpn.name
}

resource "aws_security_group" "vpn" {
  name_prefix = "${var.name}-"
  description = "Client VPN endpoint ENIs"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow traffic from associated networks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow VPN clients to reach VPC and peered networks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = var.name
  server_certificate_arn = aws_acm_certificate.server.arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = var.split_tunnel
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.vpn.id]
  dns_servers            = local.dns_servers
  transport_protocol     = var.transport_protocol
  vpn_port               = var.vpn_port
  session_timeout_hours  = var.session_timeout_hours
  self_service_portal    = "disabled"

  authentication_options {
    type = "certificate-authentication"
    # Same CA issued server and client certs; server ACM ARN is valid as the client root chain.
    root_certificate_chain_arn = aws_acm_certificate.server.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn.name
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

# count (not for_each) so subnet IDs from a sibling module can be unknown at plan time
resource "aws_ec2_client_vpn_network_association" "this" {
  count = length(var.subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.subnet_ids[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "this" {
  count = length(local.authorized_cidrs)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = local.authorized_cidrs[count.index]
  authorize_all_groups   = true
  description            = "Allow VPN clients to ${local.authorized_cidrs[count.index]}"
}

resource "local_sensitive_file" "ovpn" {
  count = var.ovpn_output_path != null ? 1 : 0

  content         = local.ovpn
  filename        = var.ovpn_output_path
  file_permission = "0600"
}
