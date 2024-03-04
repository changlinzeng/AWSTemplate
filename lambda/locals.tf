locals {
  vpc_access_enabled = length(var.vpc_config_subnets) > 0
  tags = {
    Usage = "Lambda"
  }
}
