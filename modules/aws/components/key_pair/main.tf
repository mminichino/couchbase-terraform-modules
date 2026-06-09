#

resource "aws_key_pair" "key_pair" {
  key_name   = "key-pair${var.id}"
  public_key = var.public_key

  tags = merge(var.tags, {
    Name = "key-pair-${var.id}"
  })
}
