#

data "aws_secretsmanager_secret_version" "public_key" {
  count     = var.public_key_secret_name != null ? 1 : 0
  secret_id = var.public_key_secret_name
}

data "aws_secretsmanager_secret_version" "private_key" {
  count     = var.private_key_secret_name != null ? 1 : 0
  secret_id = var.private_key_secret_name
}

locals {
  public_key = var.public_key_file != null ? trimspace(file(var.public_key_file)) : jsondecode(data.aws_secretsmanager_secret_version.public_key[0].secret_string)["key"]
  private_key = var.private_key_file != null ? file(var.private_key_file) : replace(jsondecode(data.aws_secretsmanager_secret_version.private_key[0].secret_string)["key"], "\\n", "\n")
}

resource "aws_key_pair" "key_pair" {
  key_name   = "key-pair${var.id}"
  public_key = local.public_key

  tags = merge(var.tags, {
    Name = "key-pair-${var.id}"
  })
}
