output "default_vpc_id" {
  value = aws_default_vpc.default.id
}

output "default_vpc_arn" {
  value = aws_default_vpc.default.arn
}

output "default_vpc_cidr" {
  value = aws_default_vpc.default.cidr_block
}

output "default_instance_tenant" {
  value = aws_default_vpc.default.instance_tenancy
}

output "all_vpcs" {
  value = data.aws_vpcs.all.ids
}

output "available_vpcs" {
  value = data.aws_vpcs.available.ids
}