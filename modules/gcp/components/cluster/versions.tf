terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.23.0"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  required_version = ">= 0.14"
}
