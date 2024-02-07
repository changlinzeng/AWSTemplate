output "vpc_arn" {
  value = aws_vpc.this.arn
}

output "private_subnets" {
  value = aws_subnet.private_subnets[*].arn
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*].arn
}

output "private_subnet_cidr_blocks" {
  value = var.private_subnets_cidr_blocks
}

output "public_subnet_cidr_blocks" {
  value = var.public_subnets_cidr_blocks
}

output "availability_zones" {
  value = data.aws_availability_zones.available_zones.names
}