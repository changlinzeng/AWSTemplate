data "aws_vpc" "target" {
  id = var.vpc_id
}

data "aws_ami" "redhat_9_3_0_x86_64" {
  most_recent = true
  filter {
    name   = "name"
    values = ["RHEL-9.3.0_HVM-20240117-x86_64-49-Hourly2-GP3"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  owners = ["amazon"]
}

data "aws_ami" "ubuntu_22_04_amd64" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  owners = ["amazon"]
}

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