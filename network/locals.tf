locals {
  create_public_subnet = length(var.public_subnets_cidr_blocks) > 0
}