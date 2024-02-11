data "aws_vpc" "target" {
  id = var.vpc_id
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Tier"
    values = ["Public"]
  }
}

data "aws_instances" "lb_targets" {
  instance_tags = {
    Usage = "EC2"
  }
  instance_state_names = ["running"]
}