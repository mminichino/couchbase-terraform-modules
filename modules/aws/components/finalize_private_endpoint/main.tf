# Phase 2: enable private DNS on an interface VPC endpoint after it has been
# registered with the external cloud service.
# Inputs come from modules/aws/components/ext_private_endpoint outputs.

resource "null_resource" "enable_private_dns" {
  triggers = {
    endpoint_id = var.vpc_endpoint_id
    region      = var.region
  }

  provisioner "local-exec" {
    command = "aws ec2 modify-vpc-endpoint --vpc-endpoint-id ${var.vpc_endpoint_id} --private-dns-enabled --region ${var.region}"
  }
}
