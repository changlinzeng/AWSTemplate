#module "vpc" {
#  source  = "terraform-aws-modules/vpc/aws"
#  version = "5.1.2"
#
#  name = var.vpc_name
#  cidr = var.cidr_block
#
#  azs             = var.azs
#  private_subnets = var.private_subnets_cidr_blocks
#  public_subnets  = var.public_subnets_cidr_blocks
#
#  enable_nat_gateway = false
#  enable_vpn_gateway = false
#  enable_dns_hostnames = true
#  enable_dns_support = true
#  enable_dhcp_options = true
#
#  create_database_subnet_group = false
#
#  tags = local.tags
#}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags,
    {
      Usage = "VPC"
      Name  = "${var.aws_region}-${var.vpc_name}"
    }
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  count      = local.has_secondary_cidr ? 1 : 0
  vpc_id     = aws_vpc.this
  cidr_block = var.secondary_cidr_block
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnets_cidr_blocks)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  tags = merge(var.tags,
    {
      Usage    = "VPC"
      Name     = "${var.aws_region}-${var.vpc_name}-subnet${count.index}"
      OwnerVpc = "${var.aws_region}-${var.vpc_name}"
      Tier     = "Private"
    }
  )
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnets_cidr_blocks)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  tags = merge(var.tags,
    {
      Usage    = "VPC"
      Name     = "${var.aws_region}-${var.vpc_name}-subnet${count.index}"
      OwnerVpc = "${var.aws_region}-${var.vpc_name}"
      Tier     = "Public"
    }
  )
}

resource "aws_route_table" "default_route_table" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = var.cidr_block
    gateway_id = "local"
  }
  dynamic "route" {
    for_each = local.has_secondary_cidr ? [1] : []
    content {
      cidr_block = var.secondary_cidr_block
      gateway_id = "local"
    }
  }
  tags = merge(var.tags,
    {
      Usage    = "VPC"
      Name     = "${var.aws_region}-${var.vpc_name}-default-routetable"
      OwnerVpc = "${var.aws_region}-${var.vpc_name}"
    }
  )
}

resource "aws_internet_gateway" "internet_gateway" {
  count  = local.create_public_subnet && !var.egress_only ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags,
    {
      Usage    = "VPC"
      Name     = "${var.aws_region}-${var.vpc_name}-igw"
      OwnerVpc = "${var.aws_region}-${var.vpc_name}"
    }
  )
}

resource "aws_egress_only_internet_gateway" "egress_igw" {
  count  = local.create_public_subnet && var.egress_only ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags,
    {
      Usage    = "VPC"
      Name     = "${var.aws_region}-${var.vpc_name}-egress-igw"
      OwnerVpc = "${var.aws_region}-${var.vpc_name}"
    }
  )
}

resource "aws_route_table" "igw_route_table" {
  count  = local.create_public_subnet ? 1 : 0
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = var.cidr_block
    gateway_id = "local"
  }
  dynamic "route" {
    for_each = var.secondary_cidr_block != "" ? [1] : [0]
    content {
      cidr_block = var.secondary_cidr_block
      gateway_id = "local"
    }
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.egress_only ? aws_egress_only_internet_gateway.egress_igw[0].id : aws_internet_gateway.internet_gateway[0].id
  }
  tags = merge(var.tags, {
    Usage    = "VPC"
    Name     = "${var.aws_region}-${var.vpc_name}-igw-routetable"
    OwnerVpc = "${var.aws_region}-${var.vpc_name}"
  })
}

resource "aws_route_table_association" "igw_route_table_associations" {
  count          = local.create_public_subnet ? length(var.public_subnets_cidr_blocks) : 0
  route_table_id = aws_route_table.igw_route_table[0].id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

resource "aws_security_group" "this_security_group" {
  name = "${var.aws_region}-${var.vpc_name}-sg"
  vpc_id = aws_vpc.this.id
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
  tags = merge(var.tags, {
    Usage    = "VPC"
    Name     = "${var.aws_region}-${var.vpc_name}-sg"
    OwnerVpc = "${var.aws_region}-${var.vpc_name}"
  })
}

resource "aws_network_acl" "this_nacl" {
  vpc_id = aws_vpc.this.id
  ingress {
    action     = "Allow"
    rule_no    = 100
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }
  egress {
    action     = "Allow"
    rule_no    = 100
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }
  tags = merge(var.tags, {
    Usage    = "VPC"
    Name     = "${var.aws_region}-${var.vpc_name}-default-nacl"
    OwnerVpc = "${var.aws_region}-${var.vpc_name}"
  })
}

resource "aws_network_acl_association" "acl_association_private_subnets" {
  count = length(aws_subnet.private_subnets)
  network_acl_id = aws_network_acl.this_nacl.id
  subnet_id      = aws_subnet.private_subnets[count.index].id
}

resource "aws_network_acl_association" "acl_association_public_subnets" {
  count = length(aws_subnet.public_subnets)
  network_acl_id = aws_network_acl.this_nacl.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}
