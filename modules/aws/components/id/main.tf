#

resource "random_string" "id" {
  length           = 8
  special          = false
  upper            = false
  min_numeric      = 4
  min_lower        = 4
}
