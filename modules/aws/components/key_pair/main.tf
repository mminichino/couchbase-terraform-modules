#

data "aws_secretsmanager_secret_version" "public_key" {
  secret_id = var.public_key_secret_name
}

data "aws_secretsmanager_secret_version" "private_key" {
  secret_id = var.private_key_secret_name
}

locals {
  public_key  = jsondecode(data.aws_secretsmanager_secret_version.public_key.secret_string)["key"]
  private_key = replace(jsondecode(data.aws_secretsmanager_secret_version.private_key.secret_string)["key"], "\\n", "\n")
}

resource "aws_key_pair" "key_pair" {
  key_name   = "key-pair${var.id}"
  public_key = local.public_key

  tags = merge(var.tags, {
    Name = "key-pair-${var.id}"
  })
}
