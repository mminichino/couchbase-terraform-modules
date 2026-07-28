#

output "key_name" {
  value = aws_key_pair.key_pair.key_name
}

output "public_key" {
  value = local.public_key
}

output "private_key" {
  value     = local.private_key
  sensitive = true
}
