variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "template-vpc"
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "secondary_cidr_block" {
  type    = string
  default = ""
}

variable "private_subnets_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.201.0/24",
    "10.0.202.0/24",
    "10.0.203.0/24"
  ]
}

variable "public_subnets_cidr_blocks" {
  type    = list(string)
  default = []
  #  default = [
  #    "10.0.1.0/24",
  #    "10.0.2.0/24",
  #    "10.0.3.0/24"
  #  ]
}

variable "egress_only" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  has_secondary_cidr = var.secondary_cidr_block != "" && var.secondary_cidr_block != null
}