terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.27.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "= 3.5.1"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}