data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Tier"
    values = ["Private"]
  }
}

data "aws_vpc" "target_vpc" {
  id = var.vpc_id
}