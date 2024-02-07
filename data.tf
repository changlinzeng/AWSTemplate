data "aws_region" "current" {}

data "aws_vpcs" "all" {}

data "aws_vpcs" "available" {
  filter {
    name   = "state"
    values = ["available"]
  }
}